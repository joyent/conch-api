=pod

=head1 NAME

Conch::Controller::DeviceSettings

=head1 METHODS

=cut

package Conch::Controller::DeviceSettings;

use Mojo::Base 'Mojolicious::Controller', -signatures;


=head2 set_all

Overrides all settings for a device with the given payload

=cut

sub set_all ($c) {
	my $body = $c->req->json;
	return $c->status( 400, { error => 'Payload required' } )
		unless $body;
	$c->device_settings->set_settings( $c->stash('current_device')->id, $body );
	$c->status(200);
}


=head2 set_single

Sets a single setting on a device. If the setting already exists, it is
overwritten

=cut

sub set_single ($c) {
	my $body          = $c->req->json;
	my $setting_key   = $c->param('key');
	my $setting_value = $body->{$setting_key};
	return $c->status(
		400,
		{
			error =>
"Setting key in request object must match name in the URL ('$setting_key')"
		}
	) unless $setting_value;

	$c->device_settings->set_settings( $c->stash('current_device')->id,
		{ $setting_key => $setting_value } );

	# TODO: This hard-coded setting dispatch is added for backwards
	# compatibility with Conch v1.0.0.  It is to be removed once Conch-Relay
	# and Conch-Rebooter are updated to use /device/:id/validated or the
	# orchestration system is implemented
	if ($setting_key eq 'device.validated') {
		$c->stash('current_device')->set_validated();
	}

	$c->status(200);
}


=head2 get_all

Get all settings for a device as a hash

=cut

sub get_all ($c) {
	my $settings =
		$c->device_settings->get_settings( $c->stash('current_device')->id );
	$c->status( 200, $settings );
}


=head2 get_single

Get a single setting from a device

=cut

sub get_single ($c) {
	my $setting_key = $c->param('key');
	my $settings =
		$c->device_settings->get_settings( $c->stash('current_device')->id );
	return $c->status( 404, { error => "No such setting '$setting_key'" } )
		unless $settings->{$setting_key};
	$c->status( 200, { $setting_key => $settings->{$setting_key} } );
}


=head2 delete_single

Delete a single setting from a device, provide that setting was previously set

=cut

sub delete_single ($c) {
	my $setting_key = $c->param('key');
	unless (
		$c->device_settings->delete_device_setting(
			$c->stash('current_device')->id, $setting_key
		)
		)
	{
		return $c->status( 404, { error => "No such setting '$setting_key'" } );
	}
	else {
		return $c->status(204);
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

