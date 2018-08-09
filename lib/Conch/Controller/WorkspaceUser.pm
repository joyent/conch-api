=pod

=head1 NAME

Conch::Controller::WorkspaceUser

=head1 METHODS

=cut

package Conch::Controller::WorkspaceUser;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;
use Conch::Models;
use Conch::Pg;
use List::Util 1.33 'none';

with 'Conch::Role::MojoLog';

=head2 list

Get a list of users for the current stashed C<current_workspace>

=cut

sub list ($c) {
	my $users = Conch::Model::WorkspaceUser->new->workspace_users(
		$c->stash('current_workspace')->id
	);

	$c->log->debug("Found ".scalar($users->@*)." users");
	$c->status( 200, $users );
}

=head2 invite

Invite a user to the current stashed C<current_workspace>

=cut

sub invite ($c) {
	my $body = $c->req->json;
	return $c->status(403) unless $c->is_admin;

	unless($body->{user} and $body->{role}) {
		# FIXME actually use the validator
		$c->log->warn("Input failed validation");
		return $c->status( 400, { 
			error => '"user" and "role " fields required'
		});
	}

	my @role_names = Conch::DB::Result::UserWorkspaceRole->column_info('role')->{extra}{list}->@*;
	if (none { $body->{role} eq $_ } @role_names) {
		my $role_names = join( ', ', @role_names);

		$c->log->debug("Role name '".$body->{role}."' was not one of $role_names");
		return $c->status( 400 => {
				error => '"role" must be one of: ' . $role_names 
		});
	}

	# TODO: it would be nice to be sure of which type of data we were being passed here, so we
	# don't have to look up by multiple columns.
	my $user = $c->db_user_accounts->lookup_by_email($body->{user})
		|| $c->db_user_accounts->lookup_by_name($body->{user});

	unless ($user) {
		$c->log->debug("User '".$body->{user}."' was not found");

		my $password = $c->random_string();
		$user = $c->db_user_accounts->create({
			email    => $body->{user},
			name     => $body->{user}, # FIXME: we should always have a name.
			password => $password,     # will be hashed in constructor
		});

		$c->log->info("User '".$body->{user}."' was created with ID ".$user->id);
		$c->log->info('sending new user invite mail to user ' . $user->name);
		$c->send_mail(new_user_invite => {
			name	=> $user->name,
			email	=> $user->email,
			password => $password,
		});

		# TODO update this complain when we stop sending plaintext passwords
		$c->log->warn("Email sent to ".$user->email." containing their PLAINTEXT password");
	}

	Conch::Model::Workspace->new->add_user_to_workspace(
		$user->id,
		$c->stash('current_workspace'),
		$body->{role},
	);
	$c->log->info("Add user ".$user->id." to workspace ".$c->stash('current_workspace')->id);
	$c->status(201);
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
