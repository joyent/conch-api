=pod

=head1 NAME

Conch::Controller::User

=head1 METHODS

=cut

package Conch::Controller::User;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::Model::User;
use Mojo::JSON qw(to_json);

use Data::Printer;


=head2 _user_as_v1

Provides a v1 representation of a User

=cut

sub _user_as_v1($user) {
	{
		id    => $user->id,
		email => $user->email,
		name  => $user->name,
	};
}


=head2 _settings_as_v1

Provides a v1 representation of the given user's UserSettings

=cut

sub _settings_as_v1($user) {
	my $settings = $user->settings();

	my %output;
	for my $k ( keys $settings->%* ) {
		$output{$k} = $settings->{$k};
	}
	return \%output;
}


=head2 _setting_as_v1

Provides a v1 representation of the given setting key/value pair

=cut

sub _setting_as_v1 ( $key, $value ) {
	return { $key => $value };
}

######


=head2 set_settings

Override the settings for a user with the provided payload

=cut

sub set_settings ($c) {
	my $body = $c->req->json;
	return $c->status( 400, { error => 'Payload required' } ) unless $body;

	my $user = Conch::Model::User->lookup( $c->pg, $c->stash('user_id') );
	return $c->status(401) unless $user;

	$user->set_settings($body);

	$c->status(200);
}


=head2 set_setting

Set the value of a single setting for the user

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

	my $user = Conch::Model::User->lookup( $c->pg, $c->stash('user_id') );
	return $c->status(401) unless $user;

	my $ret = $user->set_setting( $key => $value );
	if ($ret) {
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
	my $user = Conch::Model::User->lookup( $c->pg, $c->stash('user_id') );
	return $c->status(401) unless $user;

	$c->status( 200, _settings_as_v1($user) );
}


=head2 get_setting

Get the individual key/value pair for a setting for the User

=cut

sub get_setting ($c) {
	my $key = $c->param('key');

	my $user = Conch::Model::User->lookup( $c->pg, $c->stash('user_id') );
	return $c->status(401) unless $user;

	my $settings = $user->settings;

	return $c->status( 404, { error => "No such setting '$key'" } )
		unless $settings->{$key};

	$c->status( 200, _setting_as_v1( $key => $settings->{$key} ) );
}


=head2 delete_setting

Delete a single setting for a user, provided it was set previously

=cut

sub delete_setting ($c) {
	my $key = $c->param('key');

	my $user = Conch::Model::User->lookup( $c->pg, $c->stash('user_id') );
	return $c->status(401) unless $user;

	my $settings = $user->settings;

	return $c->status( 404, { error => "No such setting '$key'" } )
		unless $settings->{$key};

	if ( $user->delete_setting($key) ) {
		return $c->status(204);
	}
	else {
		return $c->status( 500 => "Failed to delete setting" );
	}
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

