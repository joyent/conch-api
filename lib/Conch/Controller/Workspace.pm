=pod

=head1 NAME

Conch::Controller::Workspace

=head1 METHODS

=cut

package Conch::Controller::Workspace;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';
use List::Util 'any';

with 'Conch::Role::MojoLog';

=head2 find_workspace

Chainable action that validates the 'workspace_id' provided in the path,
and stashes the query to get to it in C<workspace_rs>.

=cut

sub find_workspace ($c) {
	my $ws_id = $c->stash('workspace_id');

	if (not is_uuid($ws_id)) {
		return $c->status(400, { error => "Workspace ID must be a UUID. Got '$ws_id'." });
	}

	# only check if the workspace exists if user is admin on GLOBAL.
	return $c->status(404)
		if not $c->db_workspaces->search({ id => $ws_id })->count
			and $c->db_workspaces->search(
				{
					'workspace.name' => 'GLOBAL',
					'user_workspace_roles.user_id' => $c->stash('user_id'),
					'user_workspace_roles.role' => 'admin',
				},
				{ join => 'user_workspace_roles' },
			)->count;

	# HEAD, GET requires 'ro'; POST requires 'rw', PUT, DELETE requires 'admin'.
	my $method = $c->tx->req->method;
	my $requires_permission =
		(any { $method eq $_ } qw(HEAD GET)) ? 'ro'
	  : (any { $method eq $_ } qw(POST PUT)) ? 'rw'
	  : $method eq 'DELETE'                  ? 'admin'
	  : die "need handling for $method method";
	return $c->status(403)
		unless $c->user_has_workspace_auth($c->stash('workspace_id'), $requires_permission);

	# stash a resultset for easily accessing the workspace, e.g. for calling ->single, or
	# joining to.
	# No queries have been made yet, so you can add on more criteria or prefetches.
	$c->stash('workspace_rs',
		$c->db_workspaces->search_rs({ 'workspace.id' => $ws_id }));

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
		->and_workspaces_beneath($direct_workspace_ids_rs->as_query)
		->with_role_via_data_for_user($c->stash('user_id'));

	$c->status(200, [ $workspaces_rs->all ]);
}

=head2 get

Get the details of the current workspace.

Response uses the WorkspaceAndRole json schema.

=cut

sub get ($c) {

	my $workspace = $c->stash('workspace_rs')
		->with_role_via_data_for_user($c->stash('user_id'))
		->single;

	$c->status(200, $workspace);
}

=head2 get_sub_workspaces

Get all sub workspaces for the current stashed C<user_id> and current workspace (as specified
by :workspace_id in the path)

Response uses the WorkspacesAndRoles json schema.

=cut

sub get_sub_workspaces ($c) {

	my $workspaces_rs = $c->db_workspaces
		->workspaces_beneath($c->stash('workspace_id'))
		->with_role_via_data_for_user($c->stash('user_id'));

	$c->status(200, [ $workspaces_rs->all ]);
}


=head2 create_sub_workspace

Create a new subworkspace for the current workspace.

Response uses the WorkspaceAndRole json schema.

=cut

sub create_sub_workspace ($c) {
	return $c->status(403) unless $c->is_workspace_admin;

	my $input = $c->validate_input('WorkspaceCreate');
	return if not $input;

	return $c->status(400, { error => "workspace '$input->{name}' already exists" })
		if $c->db_workspaces->search({ name => $input->{name} })->count;

	my $sub_ws = $c->db_workspaces
		# we should do create_related, but due to a DBIC bug the parent_workspace_id is lost
		->create({ %$input, parent_workspace_id => $c->stash('workspace_id') });

	# signal to serializer to include role data
	$sub_ws->user_id_for_role($c->stash('user_id'));

	$c->status(201, $sub_ws);
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
