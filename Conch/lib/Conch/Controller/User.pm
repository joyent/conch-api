package Conch::Controller::User;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::Model::User;
use Mojo::JSON qw(to_json);

use Data::Printer;

sub _user_as_v1($user) {
	{
		id    => $user->id,
		email => $user->email,
		name  => $user->name,
	}
}

sub _settings_as_v1($user) {
	my $settings = $user->settings();

	my %output;
	for my $k (keys $settings->%*) {
		$output{$k} = $settings->{$k};
	}
	return \%output;
}

sub _setting_as_v1($key, $value) {
	return { $key => $value }
}

######

sub set_settings ($c) {
	my $body = $c->req->json;
	return $c->status( 400, { error => 'Payload required' } ) unless $body;

	my $user = Conch::Model::User->lookup($c->pg, $c->stash('user_id'));
	return $c->status(401) unless $user;

	$user->set_settings($body);

	$c->status(200);
}

sub set_setting ($c) {
	my $body          = $c->req->json;
	my $key   = $c->param('key');
	my $value = $body->{$key};
	return $c->status(
		400,
		{
			error => "Setting key in request object must match name in the URL ('$key')"
		}
	) unless $value;

	my $user = Conch::Model::User->lookup($c->pg, $c->stash('user_id'));
	return $c->status(401) unless $user;

	my $ret = $user->set_setting($key => $value);
	if ($ret) {
		return $c->status(200);
	} else {
		return $c->status(500, "Failed to set setting");
	}
}

sub get_settings ($c) {
	my $user = Conch::Model::User->lookup($c->pg, $c->stash('user_id'));
	return $c->status(401) unless $user;

	$c->status(200, _settings_as_v1($user));
}

sub get_setting ($c) {
	my $key = $c->param('key');

	my $user = Conch::Model::User->lookup($c->pg, $c->stash('user_id'));
	return $c->status(401) unless $user;

	my $settings = $user->settings;

	return $c->status( 
		404, 
		{ error => "No such setting '$key'" }
	) unless $settings->{$key};

	$c->status( 200, _setting_as_v1($key => $settings->{$key}));
}

sub delete_setting ($c) {
	my $key = $c->param('key');

	my $user = Conch::Model::User->lookup($c->pg, $c->stash('user_id'));
	return $c->status(401) unless $user;

	my $settings = $user->settings;


	return $c->status( 
		404, 
		{ error => "No such setting '$key'" }
	) unless $settings->{$key};

	if($user->delete_setting($key)) {
		return $c->status(204);
	} else {
		return $c->status(500 => "Failed to delete setting");
	}
}

1;
