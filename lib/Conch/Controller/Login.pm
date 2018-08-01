=pod

=head1 NAME

Conch::Controller::Login

=head1 METHODS

=cut

package Conch::Controller::Login;

use Role::Tiny::With;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::IOLoop;
use Mojo::JWT;
use Try::Tiny;
use Conch::UUID 'is_uuid';

with 'Conch::Role::MojoLog';

=head2 _create_jwt

Create a JWT and return it in the response in two parts: the signature in a
cookie named 'jwt_sig' and a response body named 'jwt_token'. 'jwt_token'
includes two claims: 'uid', for the user ID, and 'jti', for the token ID.

=cut

sub _create_jwt ( $c, $user_id ) {
	my $jwt_config = $c->app->config('jwt') || {};

	my $expires = time;
	if ( $c->is_global_admin ) {

		# default 1 month (30 days)
		$expires += $jwt_config->{global_admin_expiry} || 2592000;
	}
	else {
		# default 1 day
		$expires += $jwt_config->{normal_expiry} || 86400;
	}

	my $token = $c->db_user_session_tokens->generate_for_user($user_id, $expires);

	my $jwt = Mojo::JWT->new(
		claims => {
			uid => $user_id,
			jti => $token
		},
		secret  => $c->config('secrets')->[0],
		expires => $expires
	)->encode;

	my ( $header, $payload, $sig ) = split /\./, $jwt;

	$c->cookie(
		jwt_sig => $sig,
		{ expires => time + 3600, secure => $c->req->is_secure, httponly => 1 }
	);
	return $c->status( 200, { jwt_token => "$header.$payload" } );
}

=head2 authenticate

Handle the details of authenticating the user, with one of the following options:

1. HTTP Basic Auth
2. JWT split between Authorization Bearer header value and jwt_sig cookie
3. JWT combined with a Authorizaiton Beaer header using format "$jwt_token.$jwt_sig"
existing session for the user
4. Old 'conch' session cookie

Does not terminate the connection if authentication is sucessful, allowing for chaining to
subsequent routes and actions.

=cut

sub authenticate ($c) {

	if (my $user = $c->stash('user')) {
		$c->log->debug('already authenticated (user ' . $user->name . ')');
		return 1;
	}

	# basic auth: look for user:password in the URL
	my $abs_url = $c->req->url->to_abs;

	if ( $abs_url->userinfo ) {
		$c->log->debug('attempting to authenticate with user:password...');
		my ($name, $password) = ($abs_url->username, $abs_url->password);
		$c->log->debug('looking up user by name ' . $name . '...');
		my $user = $c->db_user_accounts->lookup_by_name($name);

		unless ($user) {
			$c->status( 401, { error => 'unauthorized' } );
			return 0;
		}

		if ($user->validate_password($password)) {
			$c->stash( user_id => $user->id );
			$c->stash( user    => $user );
			return 1;
		}
		else {
			$c->status( 401, { error => 'unauthorized' } );
			return 0;
		}
	}

	my $user_id;
	if ( $c->req->headers->authorization
		&& $c->req->headers->authorization =~ /^Bearer (.+)/ )
	{
		$c->log->debug('attempting to authenticate with Authorization: Bearer header...');
		my $token = $1;
		my $sig   = $c->cookie('jwt_sig');
		if ($sig) {
			$token = "$token.$sig";
		}

		# Attempt to decode with every configured secret, in case JWT token was
		# signed with a rotated secret
		my $jwt;
		for my $secret ( $c->config('secrets')->@* ) {
			# Mojo::JWT->decode blows up if the token is invalid
			try {
				$jwt = Mojo::JWT->new( secret => $secret )->decode($token);
			};
			last if $jwt;
		}

		# clear out all expired session tokens
		$c->db_user_session_tokens->expired->delete;

		unless ( $jwt
			and $jwt->{exp} > time
			and $c->db_user_session_tokens->search_for_user_token($jwt->{uid}, $jwt->{jti})->count )
		{
			$c->status( 401, { error => 'unauthorized' } );
			return 0;
		}
		$user_id = $jwt->{uid};
		$c->stash( 'token_id' => $jwt->{jti} );

		if ( $user_id && $sig ) {
			$c->log->debug('setting jwt_sig in cookie');
			$c->cookie(
				jwt_sig => $sig,
				{ expires => time + 3600, secure => $c->req->is_secure, httponly => 1 }
			);
		}
	}

	# did we manage to authenticate the user, or find session info indicating we did so
	# earlier (via /login)?
	$user_id ||= $c->session('user');

	unless ($user_id && is_uuid($user_id)) {
		$c->status( 401, { error => 'unauthorized' } );
		return 0;
	}

	$c->log->debug('looking up user by id ' . $user_id . '...');
	if (my $user = $c->db_user_accounts->lookup_by_id($user_id)) {
		$c->stash( user_id => $user_id );
		$c->stash( user    => $user );
		return 1;
	}

	$c->status( 401, { error => 'unauthorized' } );
	return 0;
}

=head2 session_login

Handles the act of logging in, given a user and password in the form. Returns a JWT token.

=cut

sub session_login ($c) {
	my $body = $c->req->json;

	return $c->status( 400, { error => '"user" and "password" required' } )
		unless $body->{user} and $body->{password};

	# TODO: it would be nice to be sure of which type of data we were being passed here, so we
	# don't have to look up by all columns.
	my $user = $c->db_user_accounts->lookup_by_id($body->{user})
		|| $c->db_user_accounts->lookup_by_name($body->{user})
		|| $c->db_user_accounts->lookup_by_email($body->{user});

	if (not $user->validate_password($body->{password})) {
		return $c->status(401, { error => 'Invalid login' });
	}

	$c->stash(user_id => $user->id);
	$c->stash(user => $user);

	my $feature_flags = $c->app->config('feature') || {};
	unless ( $feature_flags->{stop_conch_cookie_issue} ) {
		$c->session( 'user' => $user->id );
	}

	# clear out all expired session tokens
	$c->db_user_session_tokens->expired->delete;

	# create a JWT for this user
	return $c->_create_jwt( $user->id );
}

=head2 session_logout

Logs a user out by expiring their session

=cut

sub session_logout ($c) {
	$c->session( expires => 1 );

	# expire this user's token
	# (assuming we have the user's id, which we probably don't)
	if ($c->stash('user_id') and $c->stash('token_id')) {
		$c->db_user_session_tokens
			->search_for_user_token($c->stash('user_id'), $c->stash('token_id'))
			->active
			->expire;
	}

	# delete all expired session tokens
	$c->db_user_session_tokens->expired->delete;

	$c->cookie(
		jwt_sig => '',
		{ expires => 1, secure => $c->req->is_secure, httponly => 1 }
	) if $c->cookie('jwt_sig');

	$c->status(204);
}

=head2 reset_password

Resets a user's password, given an email address, and sends the user an email
with their new password.

=cut

sub reset_password ($c) {
	my $body = $c->req->json;
	return $c->status( 400, { error => '"email" required' } )
		unless $body->{email};

	# check for the user and sent the email non-blocking to prevent timing attacks
	Mojo::IOLoop->subprocess(
		sub {
			my $user = $c->db_user_accounts->lookup_by_email($body->{email});

			if ($user) {
				my $pw = $c->random_string();
				$user->update({ password => $pw });

				$c->mail->send_password_reset_email(
					{
						email    => $user->email,
						password => $pw,
					}
				);
			}
		},
		sub { }
	);
	return $c->status(204);
}

=head2 refresh_token

Refresh a user's JWT token. Deletes the old token.

=cut

sub refresh_token ($c) {
	# Allow users with 'conch' cookie to get a JWT without requiring
	# re-authentication. Expires 'conch' cookie
	if (my $user_id = $c->session('user') ){
		$c->session( expires => 1 );
		return $c->_create_jwt($user_id);
	}

	# expire this token
	my $token_valid = $c->db_user_session_tokens
		->search_for_user_token($c->stash('user_id'), $c->stash('token_id'))
		->active->expire;

	# clear out all expired session tokens
	$c->db_user_session_tokens->expired->delete;

	return $c->status( 403, { error => 'Invalid token ID' } )
		unless $token_valid;

	return $c->_create_jwt( $c->stash('user_id') );
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
