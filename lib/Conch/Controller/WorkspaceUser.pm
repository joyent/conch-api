=pod

=head1 NAME

Conch::Controller::WorkspaceUser

=head1 METHODS

=cut

package Conch::Controller::WorkspaceUser;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;
use List::Util 1.33 qw(none any);
use Conch::UUID 'is_uuid';

with 'Conch::Role::MojoLog';

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
				(map { $_ => $user->$_ } qw(id name email)),
				role => $role_via->role,
				$role_via->workspace_id ne $workspace_id ? ( role_via => $role_via->workspace_id ) : (),
			}
		}
		$users_rs->all
	];

	$c->log->debug('Found '.scalar($user_data->@*).' users');
	$c->status(200, $user_data);
}

=head2 invite

Invite a user to the current workspace (as specified by :workspace_id in the path)

Optionally takes a query parameter 'send_invite_mail' (defaulting to true), to send an email
to the user.

=cut

sub invite ($c) {
	return $c->status(403) unless $c->is_workspace_admin;

	my $input = $c->validate_input('WorkspaceInvite');
	return if not $input;

	# TODO: it would be nice to be sure of which type of data we were being passed here, so we
	# don't have to look up by multiple columns.
	my $rs = $c->db_user_accounts;
	my $user = $rs->lookup_by_email($input->{user}) || $rs->lookup_by_name($input->{user});

	if ($user) {
		# check if the user already has access to this workspace
		if (my $existing_role_via = $c->db_workspaces
			->role_via_for_user($c->stash('workspace_id'), $user->id)) {

			if ($existing_role_via->role eq $input->{role}) {
				$c->log->debug('user ' . $user->name
					. " already has $input->{role} access to workspace " . $c->stash('workspace_id')
					. ' via workspace ' . $existing_role_via->workspace_id
					. ': invitation not necessary');
				my $workspace = $c->stash('workspace_rs')
					->with_role_via_data_for_user($user->id)
					->single;
				return $c->status(200, $workspace);
			}

			if ($existing_role_via->role_cmp($input->{role}) > 0) {
				return $c->status(400, { error =>
						'user ' . $user->name . ' already has ' . $existing_role_via->role
					. ' access to workspace ' . $c->stash('workspace_id')
					. ($existing_role_via->workspace_id ne $c->stash('workspace_id')
						? (' via workspace ' . $existing_role_via->workspace_id) : '')
					. ": cannot downgrade role to $input->{role}" });
			}
		}
	}
	else {
		$c->log->debug("User '".$input->{user}."' was not found");

		my $password = $c->random_string();
		$user = $c->db_user_accounts->create({
			email    => $input->{user},
			name     => $input->{user}, # FIXME: we should always have a name.
			password => $password,     # will be hashed in constructor
		});

		$c->log->info("User '".$input->{user}."' was created with ID ".$user->id);
		if ($c->req->query_params->param('send_invite_mail') // 1) {
			$c->log->info('sending new user invite mail to user ' . $user->name);
			$c->send_mail(new_user_invite => {
				name	=> $user->name,
				email	=> $user->email,
				password => $password,
			});
		}

		# TODO update this complain when we stop sending plaintext passwords
		$c->log->warn("Email sent to ".$user->email." containing their PLAINTEXT password");
	}

	my $workspace_id = $c->stash('workspace_id');
	$user->update_or_create_related('user_workspace_roles' => {
		workspace_id => $workspace_id,
		role => $input->{role},
	});

	$c->log->info('Added user '.$user->id." to workspace $workspace_id");
	$c->status(201);
}

=head2 remove

Removes the indicated user from the workspace, as well as all sub-workspaces.
Requires 'admin' permissions on the workspace.

Note this may not have the desired effect if the user is getting access to the workspace via
a parent workspace. When in doubt, check at C<< GET /user/<id or name> >>.

=cut

sub remove ($c) {
	my $user_param = $c->stash('target_user');

	my $user =
		is_uuid($user_param) ? $c->db_user_accounts->lookup_by_id($user_param)
	  : $user_param =~ s/^email\=// ? $c->db_user_accounts->lookup_by_email($user_param)
	  : undef;

	return $c->status(404, { error => "user $user_param not found" })
		unless $user;

	my $rs = $c->db_workspaces
		->and_workspaces_beneath($c->stash('workspace_id'))
		->search_related('user_workspace_roles', { user_id => $user->id });

	my $num_rows = $rs->count;
	return $c->status(201) if not $num_rows;

	$c->log->debug('removing user ' . $user->name . ' from workspace '
		. $c->stash('workspace_rs')->get_column('name')->single
		. ' and all sub-workspaces (' . $num_rows . 'rows in total)');

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
