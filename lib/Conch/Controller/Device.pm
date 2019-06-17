package Conch::Controller::Device;

use Mojo::Base 'Mojolicious::Controller', -signatures;

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
    $c->log->debug('Looking up device '.$device_id.' for user '.$c->stash('user_id'));

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
        $c->log->debug('Failed to find device '.$device_id);
        return $c->status(404);
    }

    if ($c->is_system_admin) {
        $c->log->debug('User has system admin privileges to access device '.$device_id);
    }
    elsif ($device_check->{has_location}) {
        # HEAD, GET requires 'ro'; everything else (for now) requires 'rw'
        my $method = $c->req->method;
        my $requires_permission =
            (any { $method eq $_ } qw(HEAD GET)) ? 'ro'
          : (any { $method eq $_ } qw(POST PUT DELETE)) ? 'rw'
          : die 'need handling for '.$method.' method';

        if (not $c->db_devices->search({ 'device.id' => $device_id })
                ->user_has_permission($c->stash('user_id'), $requires_permission)) {
            $c->log->debug('User lacks permission to access device '.$device_id);
            return $c->status(403);
        }
    }
    else {
        # look for unlocated devices among those that have sent a device report proxied by a
        # relay using the user's credentials
        $c->log->debug('looking for device '.$device_id.' associated with relay reports');

        my $device_rs = $c->db_devices
            ->search({ 'device.id' => $device_id })
            ->related_resultset('device_relay_connections')
            ->related_resultset('relay')
            ->related_resultset('user_relay_connections')
            ->search({ 'user_relay_connections.user_id' => $c->stash('user_id') });

        if (not $device_rs->exists) {
            $c->log->debug('User lacks permission to access device '.$device_id);
            return $c->status(403);
        }
    }

    $c->log->debug('Found device '.$device_id);

    # store the simplified query to access the device, now that we've confirmed the user has
    # permission to access it.
    # No queries have been made yet, so you can add on more criteria or prefetches.
    $c->stash('device_rs', $c->db_devices->search_rs({ 'device.id' => $device_id }));

    return 1;
}

=head2 get

Retrieves details about a single (active) device.  Response uses the DetailedDevice json schema.

=cut

sub get ($c) {
    my ($device) = $c->stash('device_rs')
        ->prefetch([ { active_device_nics => 'device_neighbor' }, 'active_device_disks' ])
        ->order_by([ qw(iface_name serial_number) ])
        ->all;

    my $device_location_rs = $c->stash('device_rs')
        ->related_resultset('device_location');

    # fetch rack, room and datacenter in one query
    my $rack = $device_location_rs
        ->related_resultset('rack')
        ->prefetch({ datacenter_room => 'datacenter' })
        ->add_columns({ rack_unit_start => 'device_location.rack_unit_start' })
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
            +{
                (map +($_ => $device_nic->$_), qw(mac iface_name iface_type iface_vendor)),
                (map +($_ => $device_neighbor && $device_neighbor->$_), qw(peer_mac peer_port peer_switch)),
            }
        } $device->active_device_nics ],
        location => $rack ? +{
            rack => $rack,
            rack_unit_start => $rack->get_column('rack_unit_start'),
            datacenter_room => $rack->datacenter_room,
            datacenter => $rack->datacenter_room->datacenter,
            target_hardware_product => $device_location_rs->target_hardware_product->single,
        } : undef,
        disks => [ $device->active_device_disks ],
    };

    $c->status(200, $detailed_device);
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
    my $params = $c->validate_query_params('GetDeviceByAttribute');
    return if not $params;

    # TODO: not checking if the user has permissions to view this device.
    # need to get workspace(s) containing each device and filter them out.

    my ($key, $value) = $params->%*;
    $c->log->debug('looking up device by '.$key.' = '.$value);

    my $device_rs = $c->db_devices->prefetch('device_location')->active;
    if ($key eq 'hostname') {
        $device_rs = $device_rs->search({ $key => $value });
    }
    elsif (any { $key eq $_ } qw(mac ipaddr)) {
        $device_rs = $device_rs->search(
            { 'device_nics.'.$key => $value },
            { join => 'device_nics' },
        );
    }
    else {
        # for any other key, look for it in device_settings.
        $device_rs = $c->db_device_settings->active
            ->search({ name => $key, value => $value })
            ->related_resultset('device')
            ->prefetch('device_location')
            ->active;
    }

    my @devices = $device_rs->all;

    if (not @devices) {
        $c->log->debug('Failed to find devices matching '.$key.'='.$value);
        return $c->status(404);
    }

    $c->log->debug(scalar(@devices).' devices found');
    return $c->status(200, \@devices);
}

=head2 get_pxe

Gets PXE-specific information about a device.

Response uses the DevicePXE json schema.

=cut

sub get_pxe ($c) {
    my $device_rs = $c->stash('device_rs');
    my ($device) = $device_rs->search(
        undef,
        {
            columns => {
                id => 'device.id',
                'location.datacenter.name' => 'datacenter.region',
                'location.datacenter.vendor_name' => 'datacenter.vendor_name',
                'location.rack.name' => 'rack.name',
                'location.rack.rack_unit_start' => 'device_location.rack_unit_start',
                # pxe = the first (sorted by name) interface that is status=up
                'pxe.mac' => $device_rs->correlate('device_nics')->nic_pxe->as_query,
                # ipmi = the (newest) interface named ipmi1.
                ipmi_mac_ip => $device_rs->correlate('device_nics')->nic_ipmi->as_query,
            },
            collapse => 1,
            join => { device_location => { rack => { datacenter_room => 'datacenter' } } },
        })
        ->hri
        ->all;

    my $ipmi = delete $device->{ipmi_mac_ip};
    $device->{ipmi} = $ipmi ? { mac => $ipmi->[0], ip => $ipmi->[1] } : undef;

    $c->status(200, $device);
}

=head2 graduate

Marks the device as "graduated" (VLAN flipped)

=cut

sub graduate ($c) {
    $c->validate_request('Null');
    return if $c->res->code;

    my $device = $c->stash('device_rs')->single;
    my $device_id = $device->id;

    if (not $device->graduated) {
        $device->update({ graduated => \'now()', updated => \'now()' });
        $c->log->debug('Marked '.$device_id.' as graduated');
    }

    $c->status(303, '/device/'.$device_id);
}

=head2 set_triton_reboot

Sets the C<latest_triton_reboot> field on a device

=cut

sub set_triton_reboot ($c) {
    $c->validate_request('Null');
    return if $c->res->code;

    my $device = $c->stash('device_rs')->single;
    $device->update({ latest_triton_reboot => \'now()', updated => \'now()' });

    $c->log->debug('Marked '.$device->id.' as rebooted into triton');

    $c->status(303, '/device/'.$device->id);
}

=head2 set_triton_uuid

Sets the C<triton_uuid> field on a device, given a triton_uuid field that is a
valid UUID

=cut

sub set_triton_uuid ($c) {
    my $device = $c->stash('device_rs')->single;

    my $input = $c->validate_request('DeviceTritonUuid');
    return if not $input;

    $device->update({ triton_uuid => $input->{triton_uuid}, updated => \'now()' });
    $c->log->debug('Set the triton uuid for device '.$device->id.' to '.$input->{triton_uuid});

    $c->status(303, '/device/'.$device->id);
}

=head2 set_triton_setup

If a device has been marked as rebooted into Triton and has a Triton UUID, sets
the C<triton_setup> field. Fails if the device has already been marked as such.

=cut

sub set_triton_setup ($c) {
    $c->validate_request('Null');
    return if $c->res->code;

    my $device = $c->stash('device_rs')->single;
    my $device_id = $device->id;

    if (not defined $device->latest_triton_reboot or not defined $device->triton_uuid) {
        $c->log->warn('Input failed validation');
        return $c->status(409, {
            error => 'Device '.$device_id.' must be marked as rebooted into Triton and the Triton UUID set before it can be marked as set up for Triton'
        });
    }

    if (not $device->triton_setup) {
        $device->update({ triton_setup => \'now()', updated => \'now()' });
        $c->log->debug('Device '.$device_id.' marked as set up for triton');
    }

    $c->status(303, '/device/'.$device_id);
}

=head2 set_asset_tag

Sets the C<asset_tag> field on a device

=cut

sub set_asset_tag ($c) {
    my $input = $c->validate_request('DeviceAssetTag');
    return if not $input;

    my $device = $c->stash('device_rs')->single;

    $device->update({ asset_tag => $input->{asset_tag}, updated => \'now()' });
    $c->log->debug('Set the asset tag for device '.$device->id.' to '.($input->{asset_tag} // 'null'));

    $c->status(303, '/device/'.$device->id);
}

=head2 set_validated

Sets the C<validated> field on a device unless that field has already been set

=cut

sub set_validated ($c) {
    $c->validate_request('Null');
    return if $c->res->code;

    my $device = $c->stash('device_rs')->single;
    my $device_id = $device->id;
    return $c->status(204) if defined($device->validated);

    $device->update({ validated => \'now()', updated => \'now()' });
    $c->log->debug('Marked the device '.$device_id.' as validated');

    $c->status(303, '/device/'.$device_id);
}

=head2 get_phase

Gets just the device's phase.  Response uses the DevicePhase json schema.

=cut

sub get_phase ($c) {
    return $c->status(200, $c->stash('device_rs')->columns([qw(id phase)])->hri->single);
}

=head2 set_phase

=cut

sub set_phase ($c) {
    my $input = $c->validate_request('DevicePhase');
    return if not $input;

    $c->stash('device_rs')->update({ phase => $input->{phase}, updated => \'now()' });
    $c->log->debug('Set the phase for device '.$c->stash('device_id').' to '.$input->{phase});

    $c->status(303, '/device/'.$c->stash('device_id'));
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
