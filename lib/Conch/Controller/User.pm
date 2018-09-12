=pod

=head1 NAME

Conch::Controller::User

=head1 METHODS

=cut

package Conch::Controller::User;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::Exception;

use Conch::UUID qw( is_uuid );
use List::Util 'pairmap';
use Mojo::JSON qw(to_json from_json);

with 'Conch::Role::MojoLog';

=head2 revoke_own_tokens

Revoke the user's own session tokens.
B<NOTE>: This will cause the next request to fail authentication.

=cut

sub revoke_own_tokens ($c) {
	$c->log->debug('revoking user token for user ' . $c->stash('user')->name . ' at their request');
	$c->stash('user')->delete_related('user_session_tokens');
	$c->status(204);
}

=head2 revoke_user_tokens

Revoke a specified user's session tokens. Global admin only.

=cut

sub revoke_user_tokens ($c) {
	my $user_param = $c->stash('target_user');
	my $user =
		is_uuid($user_param) ? $c->db_user_accounts->lookup_by_id($user_param)
	  : $user_param =~ s/^email\=// ? $c->db_user_accounts->lookup_by_email($user_param)
	  : undef;

	return $c->status( 404, { error => "user $user_param not found" } )
		unless $user;

	$c->log->debug('revoking session tokens for user ' . $user->name . ', forcing them to /login again');
	$user->delete_related('user_session_tokens');
	$user->update({ refuse_session_auth => 1 });

	$c->status(204);
}

=head2 set_settings

Override the settings for a user with the provided payload

=cut

sub set_settings ($c) {
	my $body = $c->req->json;
	return $c->status( 400, { error => 'Payload required' } ) unless $body;

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	# deactivate *all* settings first
	$user->search_related('user_settings')->active->deactivate;

	# store new settings
	$user->create_related('user_settings', $_) foreach
		pairmap { +{ name => $a, value => to_json($b) } } $body->%*;

	$c->status(200);
}

=head2 set_setting

Set the value of a single setting for the user

FIXME: the key name is repeated in the URL and the payload :(

=cut

sub set_setting ($c) {
	my $body  = $c->req->json;
	my $key   = $c->stash('key');
	my $value = $body->{$key};
	return $c->status(
		400,
		{
			error =>
				"Setting key in request object must match name in the URL ('$key')"
		}
	) unless $value;

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	# FIXME? we should have a unique constraint on user_id+name
	# rather than creating additional rows.

	$user->search_related('user_settings', { name => $key })->active->deactivate;

	my $setting = $user->create_related('user_settings', {
		name => $key,
		value => to_json($value),
	});

	if ($setting) {
		return $c->status(200);
	}
	else {
		return $c->status( 500, "Failed to set setting" );
	}
}

=head2 get_settings

Get the key/values of every setting for a User

=cut

sub get_settings ($c) {
	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	# turn user_setting db rows into name => value entries,
	# newer entries overwriting older ones
	my %output = map {
		$_->name => from_json($_->value)
	} $user->user_settings->active->search({}, { order_by => 'created' });

	$c->status( 200, \%output );
}

=head2 get_setting

Get the individual key/value pair for a setting for the User

=cut

sub get_setting ($c) {
	my $key = $c->stash('key');

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $setting = $user->user_settings->active->search(
		{ name => $key },
		{ order_by => { -desc => 'created' } },
	)->one_row;

	return $c->status( 404, { error => "No such setting '$key'" } )
		unless $setting;

	$c->status( 200, { $key => from_json($setting->value) } );
}

=head2 delete_setting

Delete a single setting for a user, provided it was set previously

=cut

sub delete_setting ($c) {
	my $key = $c->stash('key');

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $count = $user->search_related('user_settings', { name => $key })->active->deactivate;

	return $c->status( 404, { error => "No such setting '$key'" } )
		unless $count;

	return $c->status(204);
}

=head2 change_own_password

Stores a new password for the current user.

Optionally takes a query parameter 'clear_tokens' (defaulting to true), to also revoke session
tokens for the user, forcing all tools to log in again.

=cut

sub change_own_password ($c) {
	my $body =  $c->validate_input('UserPassword');
	return if not $body;

	my $new_password = $body->{password};

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	$user->update({
		password => $new_password,
		refuse_session_auth => 0,
		force_password_change => 0,
	});

	$c->log->debug('updated password for user ' . $user->name . ' at their request');

	return $c->status(204)
		unless $c->req->query_params->param('clear_tokens') // 1;

	$c->stash('user')->delete_related('user_session_tokens');

	# processing continues with Conch::Controller::Login::session_logout
	return 1;
}

=head2 reset_user_password

Generates a new random password for a user. Global admin only.

Optionally takes a query parameter 'send_password_reset_mail' (defaulting to true), to send an
email to the user with the new password.

Optionally takes a query parameter 'clear_tokens' (defaulting to true), to also revoke session
tokens for the user, forcing all their tools to log in again. The user must also change their
password after logging in, as they will not be able to log in with it again.

=cut

sub reset_user_password ($c) {
	my $user_param = $c->stash('target_user');
	my $user =
		is_uuid($user_param) ? $c->db_user_accounts->lookup_by_id($user_param)
	  : $user_param =~ /^email\=/ ? $c->db_user_accounts->lookup_by_email($')
	  : undef;

	return $c->status(404, { error => "user $user_param not found" }) if not $user;

	my $new_password = $c->random_string();
	$c->log->warn('user ' . $c->stash('user')->name . ' resetting password for user ' . $user->name);
	$user->update({ password => $new_password });

	if ($c->req->query_params->param('clear_tokens') // 1) {
		$c->log->warn('user ' . $c->stash('user')->name . ' deleting user session tokens for for user ' . $user->name);
		$user->delete_related('user_session_tokens');

		$user->update({
			# subsequent attempts to authenticate with the browser session or JWT will return
			# 401 unauthorized, except for the /user/me/password endpoint
			refuse_session_auth => 1,

			# the next /login access will result in another password reset,
			# a reminder to the user to change their password,
			# and the session expiration will be reduced to 10 min
			force_password_change => 1,
		});
	}

	return $c->status(204) if not $c->req->query_params->param('send_password_reset_mail') // 1;

	$c->log->info('sending "password was changed" mail to user ' . $user->name);
	$c->send_mail(changed_user_password => {
		name     => $user->name,
		email    => $user->email,
		password => $new_password
	});
	return $c->status(202);
}

=head2 get

Gets information about a user. Global admin only.

=cut

sub get ($c) {

	my $user_param = $c->stash('target_user');

	my $user_rs = $c->db_user_accounts
		->search({}, { prefetch => { user_workspace_roles => 'workspace' } });

	my $user =
		is_uuid($user_param) ? $user_rs->lookup_by_id($user_param)
	  : $user_param =~ /^email\=/ ? $user_rs->lookup_by_email($')
	  : undef;

	return $c->status(404, { error => "user $user_param not found" }) if not $user;

	return $c->status(200, $user);
}

=head2 list

List all users and their workspaces. Global admin only.

=cut

sub list ($c) {

	my $user_rs = $c->db_user_accounts
		->active
		->search({}, { prefetch => { user_workspace_roles => 'workspace' } });

	return $c->status(200, [ $user_rs->all ]);
}

=head2 create

Creates a user. Global admin only.

Optionally takes a query parameter 'send_invite_mail' (defaulting to true), to send an email
to the user with the new password.

=cut

sub create ($c) {
	my $body =  $c->validate_input('NewUser');
	if (not $body) {
		$c->log->warn('missing body parameters when attempting to create new user');
		return;
	}

	my $name = $body->{name} // $body->{email};
	my $email = $body->{email};

	# this would cause horrible clashes with our /user routes!
	return $c->status(400, { error => 'user name "me" is prohibited', }) if $name eq 'me';

	if (my $user = $c->db_user_accounts->lookup_by_email($email)
			|| $c->db_user_accounts->lookup_by_name($name)) {
		return $c->status(409, {
			error => 'duplicate user found',
			user => { map { $_ => $user->$_ } qw(id email name created deactivated) },
		});
	}

	my $password = $body->{password} // $c->random_string;

	my $user = $c->db_user_accounts->create({
		name => $name,
		email => $email,
		password => $password,	# will be hashed in constructor
	});
	$c->log->info('created user: ' . $user->name . ', email: ' . $user->email . ', id: ' . $user->id);

	if ($c->req->query_params->param('send_invite_mail') // 1) {
		$c->log->info('sending "welcome new user" mail to user ' . $user->name);
		$c->send_mail(welcome_new_user => {
			(map { $_ => $user->$_ } qw(name email)),
			password => $password,
		});
	}

	return $c->status(201, { map { $_ => $user->$_ } qw(id email name) });
}

=head2 deactivate

Deactivates a user. Global admin only.

=cut

sub deactivate ($c) {

	my $user_param = $c->stash('target_user');
	my $user =
		is_uuid($user_param) ? $c->db_user_accounts->find({ id => $user_param })
	  : $user_param =~ /^email\=/ ? $c->db_user_accounts->find({ email => $' })
	  : undef;

	return $c->status(404, { error => "user $user_param not found" }) if not $user;

	if ($user->deactivated) {
		return $c->status(410, {
			error => 'user was already deactivated',
			user => { map { $_ => $user->$_ } qw(id email name created deactivated) },
		});
	}

	my $workspaces = join(', ', map { $_->workspace->name . ' (' . $_->role . ')' }
		$user->search_related('user_workspace_roles',{}, { join => 'workspace' }));

	$c->log->warn('user ' . $c->stash('user')->name . ' deactivating user ' . $user->name
		. ($workspaces ? ", member of workspaces: $workspaces" : ''));
	$user->update({ password => $c->random_string, deactivated => \'NOW()' });

	if ($c->req->query_params->param('clear_tokens') // 1) {
		$c->log->warn('user ' . $c->stash('user')->name . ' deleting user session tokens for for user ' . $user->name);
		$user->delete_related('user_session_tokens');
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
one at http://mozilla.org/MPL/2.0/.

=cut
