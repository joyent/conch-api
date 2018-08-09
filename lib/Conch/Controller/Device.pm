=pod

=head1 NAME

Conch::Controller::Device

=head1 METHODS

=cut

package Conch::Controller::Device;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';
use Conch::Class::DeviceDetailed;

with 'Conch::Role::MojoLog';

use Conch::Models;

=head2 under

All endpoints exist under /device/:id - C<under> looks up the device referenced
and stashes it in C<current_device> so the action isn't repeated by every
endpoint

=cut

sub under ($c) {
	my $device_id = $c->param('id');
	$c->log->debug("Looking up device $device_id for user ".$c->stash('user_id'));

	my $device = Conch::Model::Device->lookup_for_user(
		$c->stash('user_id'),
		$device_id,
	);

	if ($device) {
		$c->log->debug("Found device ".$device->id);
		$c->stash( current_device => $device );
		return 1;
	} else {
		$c->log->debug("Failed to find device $device_id");
		$c->status( 404, { error => "Device '$device_id' not found" } );
		return 0;
	}
}

=head2 get

Retrieves details about a single device, returning a serialized
Conch::Class::DeviceDetailed

=cut

sub get ($c) {
	return unless $c->under;
	my $device = $c->stash('current_device');

	my $device_report = Conch::Model::DeviceReport->new->latest_device_report( $device->id );
	my $report        = {};
	my $validations   = [];
	if ($device_report) {
		$validations = Conch::Model::DeviceReport->new
			->validation_results( $device_report->{id} );

		$report = $device_report->{report};
		delete $report->{'__CLASS__'};
	}

	my $maybe_location = Conch::Model::DeviceLocation->new->lookup($device->id);
	my $nics           = $device->device_nic_neighbors( $device->id );

	my $detailed_device = Conch::Class::DeviceDetailed->new(
		device             => $device,
		latest_report      => $report,
		validation_results => $validations,
		nics               => $nics,
		location           => $maybe_location
	);

	$c->status( 200, $detailed_device );
}

=head2 graduate

Sets the C<graduated> field on a device, unless that field has already been set

=cut

sub graduate($c) {
	my $device    = $c->stash('current_device');
	my $device_id = $device->id;

	# FIXME this shouldn't be an error
	if(defined($device->graduated)) {
		$c->log->debug("Device $device_id has already been graduated");
		return $c->status( 409 => {
			error => "Device $device_id has already been graduated"
		})
	}

	$device->graduate;
	$c->log->debug("Marked $device_id as graduated");

	$c->status(303);
	$c->redirect_to( $c->url_for("/device/$device_id")->to_abs );
}

=head2 set_triton_reboot

Sets the C<triton_reboot> field on a device

=cut

sub set_triton_reboot ($c) {
	my $device = $c->stash('current_device');
	$device->set_triton_reboot;

	$c->log->debug("Marked ".$device->id." as rebooted into triton");

	$c->status(303);
	$c->redirect_to( $c->url_for( '/device/' . $device->id )->to_abs );
}

=head2 set_triton_uuid

Sets the C<triton_uuid> field on a device, given a triton_uuid field that is a
valid UUID

=cut

sub set_triton_uuid ($c) {
	my $device = $c->stash('current_device');
	my $triton_uuid = $c->req->json && $c->req->json->{triton_uuid};

	unless(defined($triton_uuid) && is_uuid($triton_uuid)) {
		$c->log->warn("Input failed validation"); # FIXME use the validator
		return $c->status(400 => {
			error => "'triton_uuid' attribute must be present in JSON object and a UUID"
		});
	}

	$device->set_triton_uuid($triton_uuid);
	$c->log->debug("Set the triton uuid for device ".$device->id." to $triton_uuid");

	$c->status(303);
	$c->redirect_to( $c->url_for( '/device/' . $device->id )->to_abs );
}

=head2 set_triton_setup

If a device has been marked as rebooted into Triton and has a Triton UUID, sets
the C<triton_setup> field. Fails if the device has already been marked as such.

=cut

sub set_triton_setup ($c) {
	my $device    = $c->stash('current_device');
	my $device_id = $device->id;

	unless ( defined( $device->latest_triton_reboot )
		&& defined( $device->triton_uuid ) ) {

		$c->log->warn("Input failed validation");

		return $c->status(409 => {
			error => "Device $device_id must be marked as rebooted into Triton and the Trition UUID set before it can be marked as set up for Triton"
		});
	}

	# FIXME this should not be an error
	if (defined($device->triton_setup)) {
		$c->log->debug("Device $device_id has already been marked as set up for Triton");
		return $c->status( 409 => {
			error => "Device $device_id has already been marked as set up for Triton"
		})
	}

	$device->set_triton_setup;
	$c->log->debug("Device $device_id marked as set up for triton");

	$c->status(303);
	$c->redirect_to( $c->url_for("/device/$device_id")->to_abs );
}

=head2 set_asset_tag

Sets the C<asset_tag> field on a device

=cut

sub set_asset_tag ($c) {
	my $device = $c->stash('current_device');
	my $asset_tag = $c->req->json && $c->req->json->{asset_tag};

	unless(defined($asset_tag) && ref($asset_tag) eq '') {
		$c->log->warn("Input failed validation"); #FIXME use the validator
		return $c->status(400 => {
			error => "'asset_tag' attribute must be present and in JSON object a string value"
		});
	}

	$device->set_asset_tag($asset_tag);
	$c->log->debug("Set the asset tag for device ".$device->id." to $asset_tag");

	$c->status(303);
	$c->redirect_to( $c->url_for( '/device/' . $device->id )->to_abs );
}

=head2 set_validated

Sets the C<validated> field on a device unless that field has already been set

=cut

sub set_validated($c) {
	my $device    = $c->stash('current_device');
	my $device_id = $device->id;
	return $c->status(204) if defined( $device->validated );

	$device->set_validated();
	$c->log->debug("Marked the device $device_id as validated");

	$c->status(303);
	$c->redirect_to( $c->url_for("/device/$device_id")->to_abs );
}


=head2 get_role

If the device has a valid role, 303 to the relevant /role endpoint

=cut

sub get_role($c) {
	my $device = $c->stash('current_device');
	if ($device->role) {
		return $c->status(303 => "/device/role/".$device->role);
	} else {
		return $c->status(409 => { error => "device has no role" });
	}
}


=head2 set_role

Sets the device's C<role> attribute and 303's to the device endpoint

=cut

sub set_role($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $device = $c->stash('current_device');
	my $role = $c->req->json && $c->req->json->{role};
	return $c->status(
		400, {
			error => "'role' element must be present"
		}
	) unless defined($role) && ref($role) eq '';

	my $r = Conch::Model::DeviceRole->from_id($role);
	if ($r) {
		if ($r->deactivated) {
			return $c->status(400 => "Role $role is deactivated");
		}

		$device->set_role($role);
		return $c->status(303 => "/device/".$device->id);
	} else {
		return $c->status(400 => "Role $role does not exist");
	}
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
