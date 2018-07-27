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
	return $c->status( 403, { error => 'Must be global admin' } )
		unless $c->is_global_admin;

	my $user_param = $c->param('id');
	my $user =
		is_uuid($user_param) ? $c->db_user_accounts->lookup_by_id($user_param)
	  : $user_param =~ s/^email\=// ? $c->db_user_accounts->lookup_by_email($user_param)
	  : undef;

	return $c->status( 404, { error => "user $user_param not found" } )
		unless $user;

	$user->delete_related('user_session_tokens');

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
	my $key   = $c->param('key');
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
	my $key = $c->param('key');

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $setting = $user->user_settings->active->search(
		{ name => $key },
		{ order_by => { -desc => 'created' } },
	)->first;

	return $c->status( 404, { error => "No such setting '$key'" } )
		unless $setting;

	$c->status( 200, { $key => from_json($setting->value) } );
}

=head2 delete_setting

Delete a single setting for a user, provided it was set previously

=cut

sub delete_setting ($c) {
	my $key = $c->param('key');

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $count = $user->search_related('user_settings', { name => $key })->active->deactivate;

	return $c->status( 404, { error => "No such setting '$key'" } )
		unless $count;

	return $c->status(204);
}

=head2 change_password

Stores a new password for the current user.

Optionally takes a query parameter 'clear_tokens' (defaulting to true), to also revoke session
tokens for the user, forcing all tools to log in again.

=cut

sub change_password ($c) {
	my $body =  $c->validate_input('UserPassword');
	return if not $body;

	my $new_password = $body->{password};

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	$user->update({ password => $new_password });
	$c->log->debug('updated password for user ' . $user->name . ' at their request');

	return $c->status(204)
		unless $c->req->query_params->param('clear_tokens') // 1;

	$c->stash('user')->delete_related('user_session_tokens');

	# processing continues with Conch::Controller::Login::session_logout
	return 1;
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
