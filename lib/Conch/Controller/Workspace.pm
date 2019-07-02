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

If C<workspace_role> is provided, it is used as the minimum required role for the user to
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

    # HEAD, GET requires 'ro'; POST requires 'rw', PUT, DELETE requires 'admin'.
    my $method = $c->req->method;
    my $requires_role =
        (any { $method eq $_ } qw(HEAD GET)) ? 'ro'
      : (any { $method eq $_ } qw(POST PUT)) ? 'rw'
      : $method eq 'DELETE'                  ? 'admin'
      : die "need handling for $method method";
    return $c->status(403)
        if not $c->user_has_workspace_auth($c->stash('workspace_id'), $requires_role);

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
    my $direct_workspace_ids_rs = $c->stash('user')
        ->related_resultset('user_workspace_roles')
        ->distinct
        ->get_column('workspace_id');

    my $workspaces_rs = $c->db_workspaces
        ->and_workspaces_beneath($direct_workspace_ids_rs)
        ->with_role_via_data_for_user($c->stash('user_id'));

    $c->status(200, [ $workspaces_rs->all ]);
}

=head2 get

Get the details of the indicated workspace.

Response uses the WorkspaceAndRole json schema.

=cut

sub get ($c) {
    my $workspace = $c->stash('workspace_rs')
        ->with_role_via_data_for_user($c->stash('user_id'))
        ->single;

    $workspace->parent_workspace_id(undef)
        if not $c->user_has_workspace_auth($workspace->parent_workspace_id, 'ro');

    $c->status(200, $workspace);
}

=head2 get_sub_workspaces

Get all sub-workspaces for the indicated workspace.

Response uses the WorkspacesAndRoles json schema.

=cut

sub get_sub_workspaces ($c) {
    my $workspaces_rs = $c->db_workspaces
        ->workspaces_beneath($c->stash('workspace_id'))
        ->with_role_via_data_for_user($c->stash('user_id'));

    my @workspaces = $workspaces_rs->all;
    foreach my $workspace (@workspaces) {
        $workspace->parent_workspace_id(undef)
            if not $c->user_has_workspace_auth($workspace->parent_workspace_id, 'ro');
    }

    $c->status(200, \@workspaces);
}

=head2 create_sub_workspace

Create a new subworkspace for the indicated workspace.

Response uses the WorkspaceAndRole json schema.

=cut

sub create_sub_workspace ($c) {
    return $c->status(403) if not $c->is_workspace_admin;

    my $input = $c->validate_request('WorkspaceCreate');
    return if not $input;

    return $c->status(409, { error => "workspace '$input->{name}' already exists" })
        if $c->db_workspaces->search({ name => $input->{name} })->exists;

    my $sub_ws = $c->db_workspaces
        # we should do create_related, but due to a DBIC bug the parent_workspace_id is lost
        ->create({ $input->%*, parent_workspace_id => $c->stash('workspace_id') });

    # signal to serializer to include role data
    $sub_ws->user_id_for_role($c->stash('user_id'));

    $c->res->headers->location($c->url_for('/workspace/'.$sub_ws->id));
    $c->status(201, $sub_ws);
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
