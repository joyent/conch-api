=pod

=head1 NAME

Conch::Route::Device

=head1 METHODS

=cut

package Conch::Route::Device;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw(
	device_routes
);

=head2 device_routes

Sets up routes for /device

=cut

sub device_routes {
	my $r = shift;

	# Device Roles and Services
	my $dr = $r->any("/device/role");
	$dr->get('/')->to("device_roles#get_all");
	$dr->post('/')->to("device_roles#create");


	my $dri = $dr->any('/:id');
	$dri->get("/")->to("device_roles#get_one");
	$dri->post("/")->to("device_roles#update");
	$dri->delete("/")->to("device_roles#delete");
	$dri->post("/add_service")->to("device_roles#add_service");
	$dri->post("/remove_service")->to("device_roles#remove_service");

	my $drs = $r->any("/device/service");
	$drs->get('/')->to("device_services#get_all");
	$drs->post('/')->to("device_services#create");


	my $drsi = $drs->under("/:id")->to("device_services#under");
	$drsi->get('/')->to("device_services#get_one");
	$drsi->post('/')->to("device_services#update");
	$drsi->delete("/")->to("device_services#delete");


	$r->get('/device/:id')->to('device#get');

	# routes namespaced for a specific device
	my $with_device = $r->under('/device/:id')->to('device#under');

	$r->post('/device/:id')->to('device_report#process');

	$with_device->post('/report/import')->to("device_report#ct_import");
	# TODO
	# $with_device->get('/report/latest')->to("device_report#latest");
	# $r->get('/report/:id')->to("device_report#get");

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
	$with_device->get('/validation_state')
		->to('device_validation#list_validation_states');
	$with_device->get('/validation_result')
		->to('device_validation#list_validation_results');

	$with_device->get('/role')->to('device#get_role');
	$with_device->post('/role')->to('device#set_role');
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
