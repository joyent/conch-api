package Conch::Controller::WorkspaceUser;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::WorkspaceUser

=head1 METHODS

=head2 list

Get a list of users for the indicated workspace (not including system admin users).
Requires the 'admin' role on the workspace.

Response uses the WorkspaceUsers json schema.

=cut

sub list ($c) {
    my $workspace_id = $c->stash('workspace_id');

    # users who can access any ancestor of this workspace (directly)
    my $direct_users_rs = $c->db_workspaces
        ->and_workspaces_above($workspace_id)
        ->related_resultset('user_workspace_roles')
        ->related_resultset('user_account');

    # users who can access any ancestor of this workspace (through an organization)
    my $organization_users_rs = $c->db_workspaces
        ->and_workspaces_above($workspace_id)
        ->related_resultset('organization_workspace_roles')
        ->related_resultset('organization')
        ->related_resultset('user_organization_roles')
        ->related_resultset('user_account');

    my $users_rs = $direct_users_rs->union_all($organization_users_rs)
        ->active
        ->distinct
        ->order_by('user_account.name')
        ->columns([ map 'user_account.'.$_, qw(id name email) ])
        ->hri;

    my $user_data = [
        map {
            my $role_via = $c->db_workspaces->role_via_for_user($workspace_id, $_->{id});
            +{
                $_->%*, # user.id, name, email
                role => $role_via->role,
                $role_via->workspace_id ne $workspace_id
                    ? ( role_via_workspace_id => $role_via->workspace_id ) : (),
                $role_via->can('organization_id') ? ( role_via_organization_id => $role_via->organization_id ) : (),
            }
        }
        $users_rs->all
    ];

    $c->log->debug('Found '.scalar($user_data->@*).' users');
    $c->status(200, $user_data);
}

=head2 add_user

Adds a user to the indicated workspace, or upgrades an existing role entry to access the
workspace.
Requires the 'admin' role on the workspace.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to the user and to all workspace admins.

=cut

sub add_user ($c) {
    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $input = $c->validate_request('WorkspaceAddUser');
    return if not $input;

    my $user_rs = $c->db_user_accounts->active;
    my $user = $input->{user_id} ? $user_rs->find($input->{user_id})
        : $input->{email} ? $user_rs->find_by_email($input->{email})
        : undef;
    return $c->status(404) if not $user;

    return $c->status(204) if $user->is_admin;

    $c->stash('target_user', $user);
    my $workspace_id = $c->stash('workspace_id');

    # check if the user already has access to this workspace (whether directly, through a
    # parent workspace, through an organization etc)
    if (my $existing_role_via = $c->db_workspaces
            ->role_via_for_user($workspace_id, $user->id)) {
        if ((my $role_cmp = $existing_role_via->role_cmp($input->{role})) >= 0) {
            my $str = 'user '.$user->name.' already has '.$existing_role_via->role
                .' access to workspace '.$workspace_id;
            my $str2 = join(' and',
                ($existing_role_via->workspace_id ne $workspace_id
                    ? (' workspace '.$existing_role_via->workspace_id) : ()),
                ($existing_role_via->can('organization_id')
                    ? (' organization '.$existing_role_via->organization_id) : ()));
            $str .= ' via'.$str2 if $str2;

            $c->log->debug($str.': nothing to do'), return $c->status(204)
                if $role_cmp == 0;

            return $c->status(409, { error => $str.': cannot downgrade role to '.$input->{role} })
                if $role_cmp > 0;
        }

        my $rs = $user->search_related('user_workspace_roles', { workspace_id => $workspace_id });
        if ($rs->exists) {
            $rs->update({ role => $input->{role} });
        }
        else {
            $user->create_related('user_workspace_roles', {
                workspace_id => $workspace_id,
                role => $input->{role},
            });
        }

        $c->log->info('Upgraded user '.$user->id.' in workspace '.$workspace_id.' to '.$input->{role});

        if ($params->{send_mail} // 1) {
            my $workspace_name = $c->stash('workspace_name') // $c->stash('workspace_rs')->get_column('name')->single;
            $c->send_mail(
                template_file => 'workspace_user_update_user',
                From => 'noreply@'.$c->host,
                Subject => 'Your Conch access has changed',
                workspace => $workspace_name,
                role => $input->{role},
            );
            my @admins = $c->db_workspaces->and_workspaces_above($c->stash('workspace_id'))
                ->admins('with_sysadmins')
                ->search({ 'user_account.id' => { '!=' => $user->id } });
            $c->send_mail(
                template_file => 'workspace_user_update_admins',
                To => $c->construct_address_list(@admins),
                From => 'noreply@'.$c->host,
                Subject => 'We modified a user\'s access to your workspace',
                workspace => $workspace_name,
                role => $input->{role},
            ) if @admins;
        }

        return $c->status(204);
    }

    $user->create_related('user_workspace_roles', {
        workspace_id => $workspace_id,
        role => $input->{role},
    });
    $c->log->info('Added user '.$user->id.' to workspace '.$workspace_id.' with the '.$input->{role}.' role');

    if ($params->{send_mail} // 1) {
        my $workspace_name = $c->stash('workspace_name') // $c->stash('workspace_rs')->get_column('name')->single;
        $c->send_mail(
            template_file => 'workspace_user_add_user',
            From => 'noreply@'.$c->host,
            Subject => 'Your Conch access has changed',
            workspace => $workspace_name,
            role => $input->{role},
        );
        my @admins = $c->db_workspaces->and_workspaces_above($c->stash('workspace_id'))
            ->admins('with_sysadmins')
            ->search({ 'user_account.id' => { '!=' => $user->id } });
        $c->send_mail(
            template_file => 'workspace_user_add_admins',
            To => $c->construct_address_list(@admins),
            From => 'noreply@'.$c->host,
            Subject => 'We added a user to your workspace',
            workspace => $workspace_name,
            role => $input->{role},
        ) if @admins;
    }

    $c->status(204);
}

=head2 remove

Removes the indicated user from the workspace, as well as all sub-workspaces.
Requires the 'admin' role for the workspace.

Note this may not have the desired effect if the user is getting access to the workspace via
a parent workspace. When in doubt, check at C<< GET /user/<id or name> >>.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to the user and to all workspace admins.

=cut

sub remove ($c) {
    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $user = $c->stash('target_user');

    my $rs = $c->db_workspaces
        ->and_workspaces_beneath($c->stash('workspace_id'))
        ->search_related('user_workspace_roles', { user_id => $user->id });

    my $num_rows = $rs->count;
    return $c->status(204) if not $num_rows;

    my $workspace_name = $c->stash('workspace_name') // $c->stash('workspace_rs')->get_column('name')->single;

    $c->log->debug('removing user '.$user->name.' from workspace '
        .$workspace_name.' and all sub-workspaces ('.$num_rows.'rows in total)');

    my $deleted = $rs->delete;

    if ($deleted > 0 and $params->{send_mail} // 1) {
        $c->send_mail(
            template_file => 'workspace_user_remove_user',
            From => 'noreply@'.$c->host,
            Subject => 'Your Conch workspaces have been updated',
            workspace => $workspace_name,
        );
        my @admins = $c->db_workspaces->and_workspaces_above($c->stash('workspace_id'))
            ->admins('with_sysadmins')
            ->search({ 'user_account.id' => { '!=' => $user->id } });
        $c->send_mail(
            template_file => 'workspace_user_remove_admins',
            To => $c->construct_address_list(@admins),
            From => 'noreply@'.$c->host,
            Subject => 'We removed a user from your workspace',
            workspace => $workspace_name,
        ) if @admins;
    }

    return $c->status(204);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
