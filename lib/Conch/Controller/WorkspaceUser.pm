package Conch::Controller::WorkspaceUser;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

=pod

=head1 NAME

Conch::Controller::WorkspaceUser

=head1 METHODS

=head2 list

Get a list of users for the current workspace.

Response uses the WorkspaceUsers json schema.

=cut

sub list ($c) {
    # TODO: restrict to workspace admins?

    my $workspace_id = $c->stash('workspace_id');

    # users who can access any ancestor of this workspace
    my $users_rs = $c->db_workspaces
        ->and_workspaces_above($workspace_id)
        ->related_resultset('user_workspace_roles')
        ->related_resultset('user_account')
        ->active;

    my $user_data = [
        map {
            my $user = $_;
            my $role_via = $c->db_workspaces->role_via_for_user($workspace_id, $user->id);
            +{
                (map +($_ => $user->$_), qw(id name email)),
                role => $role_via->role,
                $role_via->workspace_id ne $workspace_id ? ( role_via => $role_via->workspace_id ) : (),
            }
        }
        $users_rs->all
    ];

    $c->log->debug('Found '.scalar($user_data->@*).' users');
    $c->status(200, $user_data);
}

=head2 add_user

Adds a user to the current workspace (as specified by :workspace_id in the path)

Optionally takes a query parameter 'send_mail' (defaulting to true), to send an email
to the user.

=cut

sub add_user ($c) {
    return $c->status(403) if not $c->is_workspace_admin;

    my $input = $c->validate_input('WorkspaceAddUser');
    return if not $input;

    my $user = $c->db_user_accounts->active->lookup_by_id_or_email('email='.$input->{user});
    return $c->status(404) if not $user;

    # check if the user already has access to this workspace
    if (my $existing_role_via = $c->db_workspaces
        ->role_via_for_user($c->stash('workspace_id'), $user->id)) {

        if ($existing_role_via->role eq $input->{role}) {
            $c->log->debug('user '.$user->name
                .' already has '.$input->{role}.' access to workspace '.$c->stash('workspace_id')
                .' via workspace '.$existing_role_via->workspace_id
                .': nothing to do');
            my $workspace = $c->stash('workspace_rs')
                ->with_role_via_data_for_user($user->id)
                ->single;
            return $c->status(200, $workspace);
        }

        if ($existing_role_via->role_cmp($input->{role}) > 0) {
            return $c->status(400, { error =>
                    'user '.$user->name.' already has '.$existing_role_via->role
                .' access to workspace '.$c->stash('workspace_id')
                .($existing_role_via->workspace_id ne $c->stash('workspace_id')
                    ? (' via workspace '.$existing_role_via->workspace_id) : '')
                .': cannot downgrade role to '.$input->{role} });
        }
    }

    if ($c->req->query_params->param('send_mail') // 1) {
        $c->log->info('sending welcome mail to user '.$user->name);
        $c->send_mail(workspace_add_user => {
            name    => $user->name,
            email    => $user->email,
            workspace => $c->stash('workspace_rs')->get_column('name')->single,
        });
    }

    my $workspace_id = $c->stash('workspace_id');
    $user->update_or_create_related('user_workspace_roles', {
        workspace_id => $workspace_id,
        role => $input->{role},
    });

    $c->log->info('Added user '.$user->id.' to workspace '.$workspace_id);
    $c->status(201);
}

=head2 remove

Removes the indicated user from the workspace, as well as all sub-workspaces.
Requires 'admin' permissions on the workspace.

Note this may not have the desired effect if the user is getting access to the workspace via
a parent workspace. When in doubt, check at C<< GET /user/<id or name> >>.

=cut

sub remove ($c) {
    my $user = $c->stash('target_user');

    my $rs = $c->db_workspaces
        ->and_workspaces_beneath($c->stash('workspace_id'))
        ->search_related('user_workspace_roles', { user_id => $user->id });

    my $num_rows = $rs->count;
    return $c->status(201) if not $num_rows;

    $c->log->debug('removing user '.$user->name.' from workspace '
        .$c->stash('workspace_rs')->get_column('name')->single
        .' and all sub-workspaces ('.$num_rows.'rows in total)');

    $rs->delete;

    return $c->status(201);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
