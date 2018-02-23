=pod

=head1 NAME

Conch::Route::Device

=head1 METHODS

=cut

package Conch::Route::Device;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw(
	device_routes
);

=head2 device_routes

Sets up routes for /device

=cut

sub device_routes {
	my $r = shift;

	$r->get('/device/:id')->to('device#get');

	# routes namespaced for a specific device
	my $with_device = $r->under('/device/:id')->to('device#under');

	$r->post('/device/:id')->to('device_report#process');

	$with_device->post('/graduate')->to('device#graduate');
	$with_device->post('/triton_setup')->to('device#set_triton_setup');
	$with_device->post('/triton_uuid')->to('device#set_triton_uuid');
	$with_device->post('/triton_reboot')->to('device#set_triton_reboot');
	$with_device->post('/asset_tag')->to('device#set_asset_tag');
	$with_device->post('/validated')->to('device#set_validated');

	$with_device->get('/location')->to('device_location#get');
	$with_device->post('/location')->to('device_location#set');
	$with_device->delete('/location')->to('device_location#delete');

	$with_device->get('/settings')->to('device_settings#get_all');
	$with_device->post('/settings')->to('device_settings#set_all');

	$with_device->get('/settings/#key')->to('device_settings#get_single');
	$with_device->post('/settings/#key')->to('device_settings#set_single');

	$with_device->delete('/settings/#key')->to('device_settings#delete_single');

	$with_device->post('/validation/#validation_id')
		->to('device_validation#validate');
	$with_device->post('/validation_plan/#validation_plan_id')
		->to('device_validation#run_validation_plan');
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
