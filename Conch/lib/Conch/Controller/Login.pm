package Conch::Controller::Login;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::IOLoop;
use Data::Printer;

use Conch::Model::User;

sub authenticate ($c) {
	if ( my $basic_auth = $c->req->url->to_abs->userinfo ) {
		my ( $user, $password ) = split /:/, $basic_auth;
		my $u = Conch::Model::User->lookup($c->pg, $user);
		return 0 unless $u;
		return $u->validate_password($password);
	}

	my $user_id = $c->session('user');
	unless ($user_id) {
		$c->status(401);
		return 0;
	}
	my $user = Conch::Model::User->lookup($c->pg, $user_id);
	if ($user) {
		$c->stash( user_id => $user_id );
		return 1;
	} else {
		$c->status(401);
		return 0;
	}
}

sub session_login ($c) {
	my $body = $c->req->json;

	return $c->status(
		400,
		{ error => '"user" and "password" required' }
	) unless $body->{user} and $body->{password};

	my $user = Conch::Model::User->lookup($c->pg, $body->{user});

	return $c->status(
		401,
		{ error => 'Invalid login' }
	) unless $user;

	if($user->validate_password($body->{password})) {
		$c->session( 'user' => $user->id );
		$c->status( 200, { status => 'successfully logged in' } );
	} else {
		return $c->status(
			401,
			{ error => 'Invalid login' }
		);
	}
}

sub session_logout ($c) {
	$c->session( expires => 1 );
	$c->status(204);
}

sub reset_password ($c) {
	my $body = $c->req->json;
	return $c->status(
		400,
		{ error => '"email" required' }
	) unless $body->{email};

	# check for the user and sent the email non-blocking to prevent timing attacks
	Mojo::IOLoop->subprocess(sub {
		my $user = Conch::Model::User->lookup($c->pg, $body->{email});

		if ($user) {
			my $pw = $c->random_string( length => 10 );
			$user->update_password($pw);

			$c->mail->send_password_reset_email({
				email    => $user->email,
				password => $pw,
			});
		}
	}, sub { } );
	return $c->status(204);
}

1;
