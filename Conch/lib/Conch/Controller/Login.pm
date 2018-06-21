=pod

=head1 NAME

Conch::Controller::Login

=head1 METHODS

=cut

package Conch::Controller::Login;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::IOLoop;
use Mojo::JWT;
use Try::Tiny;

use Conch::Model::User;
use Conch::Model::SessionToken;
use Conch::UUID 'is_uuid';

=head2 create_jwt

Create a JWT and return it in the response in two parts: the signature in a
cookie named 'jwt_sig' and a resposne body named 'jwt_token'. 'jwt_token'
includes two claims: 'uid', for the user ID, and 'jti', for the token ID.

=cut

sub create_jwt ( $c, $user_id ) {
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

	my $token = Conch::Model::SessionToken->create( $user_id, $expires );
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

Handle the details for authenticating a user, with one of the following options:

1. HTTP Basic Auth
2. JWT split between Authorization Bearer header value and jwt_sig cookie
3. JWT combined with a Authorizaiton Beaer header using format "$jwt_token.$jwt_sig"
existing session for the user
4. Old 'conch' session cookie

=cut

sub authenticate ($c) {
	if ( my $basic_auth = $c->req->url->to_abs->userinfo ) {
		my ( $user, $password ) = split /:/, $basic_auth;
		my $u = Conch::Model::User->lookup($user);

		unless ($u) {
			$c->status( 401, { error => 'unauthorized' } );
			return 0;
		}

		my $ret = $u->validate_password($password);
		if ($ret) {
			$c->stash( user_id => $u->id );
			$c->stash( user    => $u );
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
		my $token = $1;
		my $sig   = $c->cookie('jwt_sig');
		if ($sig) {
			$token = "$token.$sig";
		}
		my $jwt;

		# Attempt to decode with every configured secret, in case JWT token was
		# signed with a rotated secret
		for my $secret ( $c->config('secrets')->@* ) {

			# Mojo::JWT->decode blows up if the token is invalid
			try {
				$jwt = Mojo::JWT->new( secret => $secret )->decode($token);
			};
			last if $jwt;
		}
		unless ( $jwt
			&& $jwt->{exp} > time
			&& Conch::Model::SessionToken->check_token( $jwt->{uid}, $jwt->{jti} ) )
		{
			$c->status( 401, { error => 'unauthorized' } );
			return 0;
		}
		$user_id = $jwt->{uid};
		$c->stash( 'token_id' => $jwt->{jti} );

		if ( $user_id && $sig ) {
			$c->cookie(
				jwt_sig => $sig,
				{ expires => time + 3600, secure => $c->req->is_secure, httponly => 1 }
			);
		}
	}

	$user_id ||= $c->session('user');
	unless ( $user_id && is_uuid $user_id) {
		$c->status( 401, { error => 'unauthorized' } );
		return 0;
	}
	my $user = Conch::Model::User->lookup($user_id);
	if ($user) {
		$c->stash( user_id => $user_id );
		$c->stash( user    => $user );
		return 1;
	}
	else {
		$c->status( 401, { error => 'unauthorized' } );
		return 0;
	}
}

=head2 session_login

Handles the act of logging in, given a user and password. Returns a JWT token.

=cut

sub session_login ($c) {
	my $body = $c->req->json;

	return $c->status( 400, { error => '"user" and "password" required' } )
		unless $body->{user} and $body->{password};

	my $user = Conch::Model::User->lookup( $body->{user} );

	return $c->status( 401, { error => 'Invalid login' } ) unless $user;

	if ( $user->validate_password( $body->{password} ) ) {

		$c->stash( user_id => $user->id );

		my $feature_flags = $c->app->config('feature') || {};
		unless ( $feature_flags->{stop_conch_cookie_issue} ) {
			$c->session( 'user' => $user->id );
		}

		return $c->create_jwt( $user->id );
	}
	else {
		return $c->status( 401, { error => 'Invalid login' } );
	}
}

=head2 session_logout

Logs a user out by expiring their session

=cut

sub session_logout ($c) {
	$c->session( expires => 1 );

	Conch::Model::SessionToken->use_token( $c->stash('user_id'),
		$c->stash('token_id') )
		if $c->stash('token_id');

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
			my $user = Conch::Model::User->lookup( $body->{email} );

			if ($user) {
				my $pw = $c->random_string();
				$user->update_password($pw);

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
		return $c->create_jwt($user_id);
	}

	my $valid_token = Conch::Model::SessionToken->use_token( $c->stash('user_id'),
		$c->stash('token_id') );

	return $c->status( 403, { error => 'Invalid token ID' } )
		unless $valid_token;

	return $c->create_jwt( $c->stash('user_id') );
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
