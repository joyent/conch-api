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
use List::Util 'none';

with 'Conch::Role::MojoLog';

use Conch::Models;

=head2 find_device

Chainable action that validates the 'device_id' provided in the path.

=cut

sub find_device ($c) {

	my $device_id = $c->stash('device_id');
	$c->log->debug("Looking up device $device_id for user ".$c->stash('user_id'));

	my $device = Conch::Model::Device->lookup_for_user(
		$c->stash('user_id'),
		$device_id,
	);

	if (not $device) {
		$c->log->debug("Failed to find device $device_id");
		return $c->status(404, { error => "Device '$device_id' not found" });
	}

	$c->log->debug('Found device ' . $device->id);
	return 1;
}

=head2 get

Retrieves details about a single device, returning a serialized
Conch::Class::DeviceDetailed

=cut

sub get ($c) {
	my $device = Conch::Model::Device->lookup($c->stash('device_id'));

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

=head2 lookup_by_other_attribute

Looks up a device by query parameter. Supports:

	/device?mac=$macaddr
	/device?ipaddr=$ipaddr

=cut

sub lookup_by_other_attribute ($c) {
	my $params = $c->req->query_params->to_hash;

	return $c->status(404) if not keys %$params;

	return $c->status(400, { error =>
			'ambiguous query: specified multiple keys (' . join(', ', keys %$params) . ')'
		}) if keys %$params > 1;

	my ($key) = keys %$params;
	my $value = $params->{$key};

	return $c->status(400, { error => $key . 'parameter not supported' })
		if none { $key eq $_ } qw(mac ipaddr);

	$c->log->debug('looking up device by ' . $key . ' = ' . $value);

	my $device_rs;
	if ($key eq 'mac') {
		$device_rs = $c->db_devices->search(
			{ 'device_nics.mac' => $value },
			{ join => 'device_nics' },
		);
	}
	elsif ($key eq 'ipaddr') {
		$device_rs = $c->db_devices->search(
			{ 'device_nic_state.ipaddr' => $value },
			{ join => { device_nics => 'device_nic_state' } },
		);
	}

	my $device_id = $device_rs->get_column('id')->single;

	if (not $device_id) {
		$c->log->debug("Failed to find device $device_id");
		return $c->status(404, { error => "Device '$device_id' not found" });
	}

	# continue dispatch to find_device and then get.
	$c->log->debug("found device_id $device_id");
	$c->stash('device_id', $device_id);
	return 1;
}

=head2 graduate

Sets the C<graduated> field on a device, unless that field has already been set

=cut

sub graduate($c) {
	my $device = Conch::Model::Device->lookup($c->stash('device_id'));
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
	my $device = Conch::Model::Device->lookup($c->stash('device_id'));
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
	my $device = Conch::Model::Device->lookup($c->stash('device_id'));
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
	my $device = Conch::Model::Device->lookup($c->stash('device_id'));
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
	my $device = Conch::Model::Device->lookup($c->stash('device_id'));
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
	my $device = Conch::Model::Device->lookup($c->stash('device_id'));
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
	my $device = Conch::Model::Device->lookup($c->stash('device_id'));
	if ($device->device_role_id) {
		return $c->status(303 => "/device/role/".$device->device_role_id);
	} else {
		return $c->status(409 => { error => "device has no role" });
	}
}


=head2 set_role

Sets the device's C<role> attribute and 303's to the device endpoint

=cut

sub set_role($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $device = Conch::Model::Device->lookup($c->stash('device_id'));
	my $device_role_id = $c->req->json && $c->req->json->{role};
	return $c->status(
		400, {
			error => "'role' element must be present"
		}
	) unless defined($device_role_id) && ref($device_role_id) eq '';

	my $r = $c->db_device_roles->find($device_role_id);
	if ($r) {
		if ($r->deactivated) {
			return $c->status(400 => "Role $device_role_id is deactivated");
		}

		$device->set_role($device_role_id);
		return $c->status(303 => "/device/".$device->id);
	} else {
		return $c->status(400 => "Role $device_role_id does not exist");
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
