package Conch::Controller::Login;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Mojo::JWT;
use Try::Tiny;
use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::Login

=head1 METHODS

=head2 _create_jwt

Create a JWT and sets it up to be returned in the response in two parts:

	* the signature in a cookie named 'jwt_sig',
	* and a response body named 'jwt_token'. 'jwt_token' includes two claims: 'uid', for the
	  user ID, and 'jti', for the token ID.

=cut

sub _create_jwt ($c, $user_id, $expires_delta = undef) {
	my $jwt_config = $c->config('jwt') || {};

	my $expires_abs = time + (
		defined $expires_delta ? $expires_delta
			# system admin default: 30 days
	  : $c->is_system_admin ? ($jwt_config->{system_admin_expiry} || 2592000)
			# normal default: 1 day
	  : ($jwt_config->{normal_expiry} || 86400));

    my ($new_token_row, $token) = $c->db_user_session_tokens->generate_for_user(
        $user_id,
        $expires_abs,
        'login_jwt_'.int(time), # reasonably unique name
    );

	my $jwt = Mojo::JWT->new(
		claims => {
			uid => $user_id,
			jti => $token
		},
		secret  => $c->config('secrets')->[0],
		expires => $expires_abs,
	)->encode;

	my ( $header, $payload, $sig ) = split /\./, $jwt;

	$c->cookie(
		jwt_sig => $sig,
		{
			expires => $expires_abs,
			secure => $c->req->is_secure,
			httponly => 1,
		},
	);

	# this should be returned in the json payload under the 'jwt_token' key.
	return "$header.$payload";
}

=head2 authenticate

Handle the details of authenticating the user, with one of the following options:

1. HTTP Basic Auth
2. JWT split between Authorization Bearer header value and jwt_sig cookie
3. JWT combined with a Authorization Bearer header using format "$jwt_token.$jwt_sig"
existing session for the user
4. Old 'conch' session cookie

Does not terminate the connection if authentication is successful, allowing for chaining to
subsequent routes and actions.

=cut

sub authenticate ($c) {

	if (my $user = $c->stash('user')) {
		$c->log->debug('already authenticated (user ' . $user->name . ')');
		return 1;
	}

	# basic auth: look for user:password in the URL
	my $url = $c->req->url->to_abs;
	if ($url->userinfo) {

		$c->log->debug('attempting to authenticate with email:password...');
		my ($email, $password) = ($url->username, $url->password);

		$c->log->debug('looking up user by email ' . $email . '...');
		my $user = $c->db_user_accounts->active->lookup_by_id_or_email("email=$email");

		unless ($user) {
			$c->log->debug('basic auth failed: user not found');
			return $c->status(401);
		}

		if (not $user->validate_password($password)) {
			$c->log->debug('basic auth failed: incorrect password');
			return $c->status(401);
		}

		if ($user->force_password_change) {
			$c->log->debug('basic auth failed: password correct, but force_password_change was set');
			$c->res->headers->location($c->url_for('/user/me/password'));
			return $c->status(401);
		}

		# pass through to whatever action the user was trying to reach
		$c->log->debug('user '.$user->name.' ('.$user->email.') accepted using basic auth');
		$c->stash(user_id => $user->id);
		$c->stash(user    => $user);
		return 1;
	}

	my ($user_id, $jwt, $jwt_sig, $session_token);
	if ( $c->req->headers->authorization
		&& $c->req->headers->authorization =~ /^Bearer (.+)/ )
	{
		$c->log->debug('attempting to authenticate with Authorization: Bearer header...');
		my $token = $1;
		$jwt_sig = $c->cookie('jwt_sig');
		if ($jwt_sig) {
			$token = "$token.$jwt_sig";
		}

		# Attempt to decode with every configured secret, in case JWT token was
		# signed with a rotated secret
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
            and $session_token = $c->db_user_session_tokens
                ->unexpired
                ->search_for_user_token($jwt->{uid}, $jwt->{jti})->single)
		{
			$c->log->debug('JWT auth failed');
			return $c->status(401);
		}

        $session_token->update({ last_used => \'now()' });
		$user_id = $jwt->{uid};
        $c->stash('token_id', $jwt->{jti});
	}

	# did we manage to authenticate the user, or find session info indicating we did so
	# earlier (via /login)?
	$user_id ||= $c->session('user');

	if ($user_id and is_uuid($user_id)) {
		$c->log->debug('looking up user by id ' . $user_id . '...');
		if (my $user = $c->db_user_accounts->active->lookup_by_id_or_email($user_id)) {
			if ($user_id and $jwt_sig) {
				$c->log->debug('setting jwt_sig in cookie');
				$c->cookie(
					jwt_sig => $jwt_sig,
					{ expires => time + 3600, secure => $c->req->is_secure, httponly => 1 }
				);
			}

            # api tokens are exempt from this check
            if ((not $session_token or $session_token->is_login)
                    and $user->refuse_session_auth) {
				if ($user->force_password_change) {
					if ($c->req->url ne '/user/me/password') {
						$c->log->debug('attempt to authenticate before changing insecure password');

						# ensure session and and all login JWTs expire in no more than 10 minutes
						$c->session(expiration => 10 * 60);
                        $user->user_session_tokens->login_only
                            ->update({ expires => \'least(expires, now() + interval \'10 minutes\')' }) if $session_token;

						$c->res->headers->location($c->url_for('/user/me/password'));
						return $c->status(401);
					}
				}
				else {
					$c->log->debug('user\'s tokens were revoked - they must /login again');
					return $c->status(401);
				}
			}

			$c->stash( user_id => $user_id );
			$c->stash( user    => $user );
			return 1;
		}
	}

	$c->log->debug('auth failed: no credentials provided');
	return $c->status(401);
}

=head2 session_login

Handles the act of logging in, given a user and password in the form. Returns a JWT token.

=cut

sub session_login ($c) {
	my $input = $c->validate_input('Login');
	if (not $input) {
		$c->log->debug('session login failed validation');
		return;
	}

	# TODO: it would be nice to be sure of which type of data we were being passed here, so we
	# don't have to look up by all columns.
	my $user_rs = $c->db_user_accounts->active;
	my $user = $user_rs->lookup_by_id_or_email($input->{user})
		|| $user_rs->lookup_by_id_or_email("email=$input->{user}");

	if (not $user) {
		$c->log->debug("user lookup for $input->{user} failed");
		return $c->status(401, { error => 'unauthorized' });
	}

	if (not $user->validate_password($input->{password})) {
		$c->log->debug("password validation for $input->{user} failed");
		return $c->status(401, { error => 'unauthorized' });
	}

	$c->stash(user_id => $user->id);
	$c->stash(user => $user);

	unless ($c->feature('stop_conch_cookie_issue')) {
		$c->session( 'user' => $user->id );
	}

    # expire and delete any old session login JWTs for this user (there should only be one!)
    $user->user_session_tokens->login_only->unexpired->expire;

	# clear out all expired session tokens
	$c->db_user_session_tokens->expired->delete;

	if ($user->force_password_change) {
		$c->log->info('user ' . $user->name . ' logging in with one-time insecure password');
		$user->update({
			last_login => \'NOW()',
			password => $c->random_string,	# ensure password cannot be used again
		});
		# password must be reset within 10 minutes
		$c->session(expires => time + 10 * 60);

		# we logged the user in, but he must now change his password (within 10 minutes)
		$c->res->code(200);
		$c->res->headers->location($c->url_for('/user/me/password'));
		my $payload = { jwt_token => $c->_create_jwt($user->id, 10 * 60) };
		$c->respond_to(
			json => { json => $payload },
			any  => { json => $payload },
		);
		return 0;
	}

	# allow the user to use session auth again
	$user->update({
		last_login => \'NOW()',
		refuse_session_auth => 0,
	});

	return $c->status(200, {
		jwt_token => $c->_create_jwt($user->id),
	});
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
			->unexpired
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
    my $input = $c->validate_input('ResetPassword');
    return if not $input;
    return $c->status(301, '/user/email='.$input->{email}.'/password');
}

=head2 refresh_token

Refresh a user's JWT token. Deletes the old token.

=cut

sub refresh_token ($c) {
	# Allow users with 'conch' cookie to get a JWT without requiring
	# re-authentication. Expires 'conch' cookie
	if (my $user_id = $c->session('user') ){
		$c->session( expires => 1 );
		return $c->status(200, { jwt_token => $c->_create_jwt($user_id) } );
	}

	# expire this token
	my $token_valid = $c->db_user_session_tokens
		->search_for_user_token($c->stash('user_id'), $c->stash('token_id'))
		->unexpired->expire;

	# clear out all expired session tokens
	$c->db_user_session_tokens->expired->delete;

	return $c->status( 403, { error => 'Invalid token ID' } )
		unless $token_valid;

	return $c->status(200, { jwt_token => $c->_create_jwt($c->stash('user_id')) } );
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
