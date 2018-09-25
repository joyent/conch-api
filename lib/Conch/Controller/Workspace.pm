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
and stashes the query to get to it in C<user_workspace_role_rs>.

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

	# stash a resultset for easily accessing the current uwr + workspace,
	# e.g. for calling ->single, or joining to.
	$c->stash('user_workspace_role_rs',
		$c->stash('user')->search_related_rs('user_workspace_roles',
			{ workspace_id => $ws_id },
			{ prefetch => 'workspace' },
		));

	# ...and a resultset for accessing the workspace itself, for when we don't need to check
	# the permissions
	$c->stash('workspace_rs',
		$c->db_workspaces->search_rs({ 'workspace.id' => $ws_id }));

	return 1;
}

=head2 list

Get a list of all workspaces available to the currently authenticated user.
Returns a listref of hashrefs with keys: id name description role parent_id

=cut

sub list ($c) {
	my $wss_data = [
		map {
			my $uwr = $_;
			+{
				(map { $_ => $uwr->workspace->$_ } qw(id name description)),
				parent_id => $uwr->workspace->parent_workspace_id,
				role => $uwr->role,
			}
		}
		$c->stash('user')
			->related_resultset('user_workspace_roles')
			->prefetch('workspace')
			->all
	];

	$c->status(200, $wss_data);
}

=head2 get

Get the details of the current workspace.
Returns a hashref with keys: id, name, description, role, parent_id.

=cut

sub get ($c) {
	my $uwr = $c->stash('user_workspace_role_rs')->single;

	# FIXME: this check is already done in find_workspace
	return $c->status(404, { error => 'Workspace ' . $c->stash('workspace_id') . ' not found' })
		if not $uwr;

	my $ws_data = +{
		(map { $_ => $uwr->workspace->$_ } qw(id name description)),
		parent_id => $uwr->workspace->parent_workspace_id,
		role => $uwr->role,
	};

	$c->status(200, $ws_data);
}

=head2 get_sub_workspaces

Get all sub workspaces for the current stashed C<user_id> and current workspace (as specified
by :workspace_id in the path)

=cut

sub get_sub_workspaces ($c) {

	my $wss_data = [
		map {
			my $ws = $_;
			+{
				(map { $_ => $ws->$_ } qw(id name description)),
				parent_id => $ws->parent_workspace_id,
				role => ($ws->user_workspace_roles)[0]->role,
			}
		}
		$c->db_workspaces->workspaces_beneath($c->stash('workspace_id'))
			->search(
				{ 'user_workspace_roles.user_id' => $c->stash('user_id') },
				{ prefetch => 'user_workspace_roles' },
			)->all
	];

	$c->status(200, $wss_data);
}


=head2 create_sub_workspace

Create a new subworkspace for the current workspace.
Returns a hashref with keys: id, name, description, role, parent_id.

=cut

sub create_sub_workspace ($c) {
	return $c->status(403) unless $c->is_workspace_admin;

	my $input = $c->validate_input('WorkspaceCreate');
	return if not $input;

	return $c->status(400, { error => "workspace '$input->{name}' already exists" })
		if $c->db_workspaces->search({ name => $input->{name} })->count;

	my $uwr = $c->stash('user_workspace_role_rs')->single;

	my $sub_ws = $uwr->workspace->create_related(
		workspaces => {
			name => $input->{name},
			description => $input->{description},
			user_workspace_roles => [{
				user_id => $uwr->user_id,
				role => $uwr->role,
			}],
		},
	);

	my $ws_data = +{
		(map { $_ => $sub_ws->$_ } qw(id name description)),
		parent_id => $sub_ws->parent_workspace_id,
		role => $uwr->role,
	};

	$c->status(201, $ws_data);
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
