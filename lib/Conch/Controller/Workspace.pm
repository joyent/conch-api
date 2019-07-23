package Conch::Controller::Workspace;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';
use List::Util 'any';

=pod

=head1 NAME

Conch::Controller::Workspace

=head1 METHODS

=head2 find_workspace

Chainable action that validates the C<workspace_id> or C<workspace_name> provided in the path,
and stashes the query to get to it in C<workspace_rs>.

If C<workspace_name> is provided, C<workspace_id> is looked up and stashed.

If C<require_role> is provided, it is used as the minimum required role for the user to
continue.

=cut

sub find_workspace ($c) {
    my $identifier = $c->stash('workspace_id_or_name');

    if (is_uuid($identifier)) {
        $c->stash('workspace_id', $identifier);
    }
    else {
        $c->stash('workspace_name', $identifier);
        $c->stash('workspace_id', $c->db_workspaces->search({ name => $identifier })->get_column('id')->single);
    }

    # only check if the workspace exists if user is a system admin
    if ($c->is_system_admin) {
        # if we have no id at this point, we already know the workspace doesn't exist
        # if we already turned a name -> id, we already know the workspace exists
        return $c->status(404)
            if not $c->stash('workspace_id')
                or (not $c->stash('workspace_name')
                    and not $c->db_workspaces->search({ id => $c->stash('workspace_id') })->exists);
    }
    else {
        # if no minimum role was specified, use a heuristic:
        # HEAD, GET requires 'ro'; POST requires 'rw', PUT, DELETE requires 'admin'.
        my $method = $c->req->method;
        my $requires_role = $c->stash('require_role') //
           ((any { $method eq $_ } qw(HEAD GET)) ? 'ro'
          : (any { $method eq $_ } qw(POST PUT)) ? 'rw'
          : $method eq 'DELETE'                  ? 'admin'
          : die "need handling for $method method");
        if (not $c->_user_has_workspace_auth($c->stash('workspace_id'), $requires_role)) {
            $c->log->debug('User lacks the required role ('.$requires_role.') for workspace '.$identifier);
            return $c->status(403);
        }
    }

    # stash a resultset for easily accessing the workspace, e.g. for calling ->single, or
    # joining to.
    # No queries have been made yet, so you can add on more criteria or prefetches.
    $c->stash('workspace_rs',
        $c->db_workspaces->search_rs({ 'workspace.id' => $c->stash('workspace_id') }));

    return 1;
}

=head2 list

Get a list of all workspaces available to the currently authenticated user.

Response uses the WorkspacesAndRoles json schema.

=cut

sub list ($c) {
    if ($c->is_system_admin) {
        my $rs = $c->db_workspaces->add_role_column('admin');
        return $c->status(200, [ $rs->all ]);
    }

    my $direct_workspace_ids_rs = $c->stash('user')
        ->related_resultset('user_workspace_roles')
        ->distinct
        ->get_column('workspace_id');
    my @data = $c->db_workspaces
        ->and_workspaces_beneath($direct_workspace_ids_rs)
        ->with_role_via_data_for_user($c->stash('user_id'))
        ->all;

    my %workspace_ids; @workspace_ids{map $_->id, @data} = ();
    foreach my $ws (@data) {
        $ws->parent_workspace_id(undef)
            if $ws->parent_workspace_id and not exists $workspace_ids{$ws->parent_workspace_id};
    }

    $c->status(200, \@data);
}

=head2 get

Get the details of the indicated workspace.

Response uses the WorkspaceAndRole json schema.

=cut

sub get ($c) {
    my $workspace;
    if ($c->is_system_admin) {
        $workspace = $c->stash('workspace_rs')->add_role_column('admin')->single;
    }
    else {
        $workspace = $c->stash('workspace_rs')
            ->with_role_via_data_for_user($c->stash('user_id'))
            ->single;
        $workspace->parent_workspace_id(undef)
            if not $c->_user_has_workspace_auth($workspace->parent_workspace_id, 'ro');
    }

    $c->status(200, $workspace);
}

=head2 get_sub_workspaces

Get all sub-workspaces for the indicated workspace.

Response uses the WorkspacesAndRoles json schema.

=cut

sub get_sub_workspaces ($c) {
    my $workspaces_rs = $c->db_workspaces->workspaces_beneath($c->stash('workspace_id'));

    if ($c->is_system_admin) {
        $workspaces_rs = $workspaces_rs->add_role_column('admin');
    }
    else {
        $workspaces_rs = $workspaces_rs->with_role_via_data_for_user($c->stash('user_id'));
    }

    my @workspaces = $workspaces_rs->all;
    if (not $c->is_system_admin) {
        foreach my $workspace (@workspaces) {
            $workspace->parent_workspace_id(undef)
                if $workspace->id eq $c->stash('workspace_id')
                    and not $c->_user_has_workspace_auth($workspace->parent_workspace_id, 'ro');
        }
    }

    $c->status(200, \@workspaces);
}

=head2 create_sub_workspace

Create a new subworkspace for the indicated workspace. The user is given the 'admin' role on
the new workspace.

Response uses the WorkspaceAndRole json schema.

=cut

sub create_sub_workspace ($c) {
    my $input = $c->validate_request('WorkspaceCreate');
    return if not $input;

    return $c->status(409, { error => "workspace '$input->{name}' already exists" })
        if $c->db_workspaces->search({ name => $input->{name} })->exists;

    my $sub_ws = $c->db_workspaces
        # we should do create_related, but due to a DBIC bug the parent_workspace_id is lost
        ->create({ $input->%*, parent_workspace_id => $c->stash('workspace_id') });

    # signal to serializer to include role data
    if ($c->is_system_admin) {
        $sub_ws->role('admin');
    }
    elsif ($c->_user_has_workspace_auth($c->stash('workspace_id'), 'admin')) {
        $sub_ws->user_id_for_role($c->stash('user_id'));
    }
    else {
        $sub_ws->create_related('user_workspace_role', { role => 'admin' });
        $sub_ws->role('admin');
    }

    $c->res->headers->location($c->url_for('/workspace/'.$sub_ws->id));
    $c->status(201, $sub_ws);
}

=head2 _user_has_workspace_auth

Verifies that the user indicated by the stashed C<user_id> has (at least) this role on the
workspace indicated by the provided C<workspace_id> or one of its ancestors.

=cut

sub _user_has_workspace_auth ($c, $workspace_id, $role_name) {
    return 0 if not $c->stash('user_id');

    $c->db_workspaces
        ->and_workspaces_above($workspace_id)
        ->related_resultset('user_workspace_roles')
        ->user_has_role($c->stash('user_id'), $role_name);
};

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
