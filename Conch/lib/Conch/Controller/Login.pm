=pod

=head1 NAME

Conch::Controller::Login

=head1 METHODS

=cut

package Conch::Controller::Login;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::IOLoop;
use Data::Printer;

use Conch::Model::User;


=head2 authenticate

Handle the details for authenticating a user, via either HTTP Basic Auth or an
existing session for the user

=cut

sub authenticate ($c) {
	if ( my $basic_auth = $c->req->url->to_abs->userinfo ) {
		my ( $user, $password ) = split /:/, $basic_auth;
		my $u = Conch::Model::User->lookup( $user );
		return 0 unless $u;

		my $ret = $u->validate_password($password);
		if ($ret) {
			$c->stash(user_id => $u->id);
			$c->stash(user => $u);
		}
		return $ret;
	}

	my $user_id = $c->session('user');
	unless ($user_id) {
		$c->status(401, { error => 'unauthorized'});
		return 0;
	}
	my $user = Conch::Model::User->lookup( $user_id );
	if ($user) {
		$c->stash( user_id => $user_id );
		$c->stash(user => $user);
		return 1;
	}
	else {
		$c->status(401, { error => 'unauthorized'});
		return 0;
	}
}


=head2 session_login

Handles the act of logging in, given a user and password

=cut

sub session_login ($c) {
	my $body = $c->req->json;

	return $c->status( 400, { error => '"user" and "password" required' } )
		unless $body->{user} and $body->{password};

	my $user = Conch::Model::User->lookup( $body->{user} );

	return $c->status( 401, { error => 'Invalid login' } ) unless $user;

	if ( $user->validate_password( $body->{password} ) ) {
		$c->session( 'user' => $user->id );
		$c->status( 200, { status => 'successfully logged in' } );
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
				my $pw = $c->random_string( length => 10 );
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

1;


__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

