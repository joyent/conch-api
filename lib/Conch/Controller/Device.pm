package Conch::Controller::Device;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use List::Util 'any';
use Mojo::JSON 'from_json';

=pod

=head1 NAME

Conch::Controller::Device

=head1 METHODS

=head2 find_device

Chainable action that validates the 'device_id' provided in the path.

=cut

sub find_device ($c) {

	my $device_id = $c->stash('device_id');
	$c->log->debug("Looking up device $device_id for user ".$c->stash('user_id'));

    # fetch for device existence and location in one query
    my $device_check = $c->db_devices
        ->search(
            { id => $device_id },
            {
                join => 'device_location',
                select => [
                    { '' => \1, -as => 'exists' },
                    { '' => \'device_location.rack_id is not null', -as => 'has_location' },
                ],
            },
        )
        ->active
        ->hri
        ->single;

    # if the device doesn't exist, we can bail out right now
    if (not $device_check->{exists}) {
        $c->log->debug("Failed to find device $device_id");
        return $c->status(404, { error => 'Not found' });
    }

    if ($device_check->{has_location}) {
        # HEAD, GET requires 'ro'; everything else (for now) requires 'rw'
        my $method = $c->req->method;
        my $requires_permission =
            (any { $method eq $_ } qw(HEAD GET)) ? 'ro'
          : (any { $method eq $_ } qw(POST PUT DELETE)) ? 'rw'
          : die "need handling for $method method";

        if (not $c->db_devices->search({ 'device.id' => $device_id })
                ->user_has_permission($c->stash('user_id'), $requires_permission)) {
            $c->log->debug('User lacks permission to access device '.$device_id);
            return $c->status(403, { error => 'Forbidden' });
        }
    }
    else {
        # look for unlocated devices among those that have sent a device report proxied by a
        # relay using the user's credentials
        $c->log->debug("looking for device $device_id associated with relay reports");

        my $device_rs = $c->db_devices
            ->search({ 'device.id' => $device_id })
            ->related_resultset('device_relay_connections')
            ->related_resultset('relay')
            ->related_resultset('user_relay_connections')
            ->search({ 'user_relay_connections.user_id' => $c->stash('user_id') });

        if (not $device_rs->exists) {
            $c->log->debug('User lacks permission to access device '.$device_id);
            return $c->status(403, { error => 'Forbidden' });
        }
    }

	$c->log->debug('Found device ' . $device_id);

	# store the simplified query to access the device, now that we've confirmed the user has
	# permission to access it.
	# No queries have been made yet, so you can add on more criteria or prefetches.
	$c->stash('device_rs', $c->db_devices->search_rs({ 'device.id' => $device_id }));

	return 1;
}

=head2 get

Retrieves details about a single device, returning a json-schema 'DetailedDevice' structure.

=cut

sub get ($c) {

	my ($device) = $c->stash('device_rs')
		->prefetch([ { device_nics => 'device_neighbor' }, 'device_disks' ])
		->order_by([ qw(iface_name serial_number) ])
		->all;

	my $location = $c->stash('device_rs')
		->related_resultset('device_location')
		->get_detailed
		->single;

	my $latest_report = $c->stash('device_rs')
		->latest_device_report
		->columns([qw(report invalid_report)])
		->single;

	my $detailed_device = +{
		$device->TO_JSON->%*,
		latest_report_is_invalid => \($latest_report && $latest_report->invalid_report ? 1 : 0),
		latest_report => $latest_report && $latest_report->report ? from_json($latest_report->report) : undef,
		# if not null, this is text - maybe json-encoded, maybe random junk
		invalid_report => $latest_report ? $latest_report->invalid_report : undef,
		nics => [ map {
			my $device_nic = $_;
			my $device_neighbor = $device_nic->device_neighbor;
			$device_nic->deactivated ? () :
			+{
				(map { $_ => $device_nic->$_ } qw(mac iface_name iface_type iface_vendor)),
				(map { $_ => $device_neighbor && $device_neighbor->$_ } qw(peer_mac peer_port peer_switch)),
			}
		} $device->device_nics ],
		location => $location,
		disks => [ map { $_->deactivated ? () : $_->TO_JSON } $device->device_disks ],
	};

	$c->status( 200, $detailed_device );
}

=head2 lookup_by_other_attribute

Looks up one or more devices by query parameter. Supports:

	/device?hostname=$hostname
	/device?mac=$macaddr
	/device?ipaddr=$ipaddr
	/device?$setting_key=$setting_value

Response uses the Devices json schema.

=cut

sub lookup_by_other_attribute ($c) {
	my $params = $c->req->query_params->to_hash;

	return $c->status(404) if not keys %$params;

	return $c->status(400, { error =>
			'ambiguous query: specified multiple keys (' . join(', ', keys %$params) . ')'
		}) if keys %$params > 1;

    # TODO: not checking if the user has permissions to view this device.
    # need to get workspace(s) containing each device and filter them out.

	my ($key) = keys %$params;
	my $value = $params->{$key};

	$c->log->debug('looking up device by ' . $key . ' = ' . $value);

	my $device_rs;
	if ($key eq 'hostname') {
		$device_rs = $c->db_devices->active->search({ $key => $value });
	}
	elsif (any { $key eq $_ } qw(mac ipaddr)) {
		$device_rs = $c->db_devices->active->search(
			{ "device_nics.$key" => $value },
			{ join => 'device_nics' },
		);
	}
	else {
		# for any other key, look for it in device_settings.
		$device_rs = $c->db_device_settings->active
			->search({ name => $key, value => $value })
			->related_resultset('device')->active;
	}

	my @devices = $device_rs->all;

	if (not @devices) {
		$c->log->debug("Failed to find devices matching $key=$value.");
		return $c->status(404, { error => 'Devices not found' });
	}

	$c->log->debug(scalar(@devices).' devices found');
	return $c->status(200, \@devices);
}

=head2 graduate

Marks the device as "graduated" (VLAN flipped)

=cut

sub graduate($c) {
	my $device = $c->stash('device_rs')->single;
	my $device_id = $device->id;

	# FIXME this shouldn't be an error
	if(defined($device->graduated)) {
		$c->log->debug("Device $device_id has already been graduated");
		return $c->status( 409 => {
			error => "Device $device_id has already been graduated"
		})
	}

	$device->update({ graduated => \'NOW()', updated => \'NOW()' });
	$c->log->debug("Marked $device_id as graduated");

	$c->status(303);
	$c->redirect_to($c->url_for("/device/$device_id"));
}

=head2 set_triton_reboot

Sets the C<latest_triton_reboot> field on a device

=cut

sub set_triton_reboot ($c) {
	my $device = $c->stash('device_rs')->single;
	$device->update({ latest_triton_reboot => \'NOW()', updated => \'NOW()' });

	$c->log->debug("Marked ".$device->id." as rebooted into triton");

	$c->status(303);
	$c->redirect_to($c->url_for('/device/' . $device->id));
}

=head2 set_triton_uuid

Sets the C<triton_uuid> field on a device, given a triton_uuid field that is a
valid UUID

=cut

sub set_triton_uuid ($c) {
	my $device = $c->stash('device_rs')->single;

	my $input = $c->validate_input('DeviceTritonUuid');
	return if not $input;

	$device->update({ triton_uuid => $input->{triton_uuid}, updated => \'NOW()' });
	$c->log->debug("Set the triton uuid for device ".$device->id." to $input->{triton_uuid}");

	$c->status(303);
	$c->redirect_to($c->url_for('/device/' . $device->id));
}

=head2 set_triton_setup

If a device has been marked as rebooted into Triton and has a Triton UUID, sets
the C<triton_setup> field. Fails if the device has already been marked as such.

=cut

sub set_triton_setup ($c) {
	my $device = $c->stash('device_rs')->single;
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

	$device->update({ triton_setup => \'NOW()', updated => \'NOW()' });
	$c->log->debug("Device $device_id marked as set up for triton");

	$c->status(303);
	$c->redirect_to($c->url_for("/device/$device_id"));
}

=head2 set_asset_tag

Sets the C<asset_tag> field on a device

=cut

sub set_asset_tag ($c) {
	my $input = $c->validate_input('DeviceAssetTag');
	return if not $input;

	my $device = $c->stash('device_rs')->single;

	$device->update({ asset_tag => $input->{asset_tag}, updated => \'NOW()' });
	$c->log->debug("Set the asset tag for device ".$device->id." to $input->{asset_tag}");

	$c->status(303);
	$c->redirect_to($c->url_for('/device/' . $device->id));
}

=head2 set_validated

Sets the C<validated> field on a device unless that field has already been set

=cut

sub set_validated($c) {
	my $device = $c->stash('device_rs')->single;
	my $device_id = $device->id;
	return $c->status(204) if defined( $device->validated );

	$device->update({ validated => \'NOW()', updated => \'NOW()' });
	$c->log->debug("Marked the device $device_id as validated");

	$c->status(303);
	$c->redirect_to($c->url_for("/device/$device_id"));
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
