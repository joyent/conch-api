package Conch::Controller::Device;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';
use List::Util 'any';
use Mojo::JSON 'from_json';
use Digest::MD5 ();

=pod

=head1 NAME

Conch::Controller::Device

=head1 METHODS

=head2 find_device

Chainable action that uses the C<device_id_or_serial_number> provided in the path
to find the device and verify the user has the required role to operate on it.

If C<require_role> is provided, it is used as the minimum required role for the user to
continue.

=cut

sub find_device ($c) {
    my $rs = $c->db_devices;
    my $identifier;
    if ($identifier = $c->stash('device_id')) {
        $rs = $rs->search({ id => $identifier });
    }
    elsif ($identifier = $c->stash('device_serial_number')) {
        $rs = $rs->search({ serial_number => $identifier });
    }
    elsif ($identifier = $c->stash('device_id_or_serial_number')) {
        $rs = $rs->search({
            is_uuid($identifier)
          ? do { $c->stash('device_id', $identifier); ( id => $identifier ) }
          : do { $c->stash('device_serial_number', $identifier); ( serial_number => $identifier ) }
        });
    }
    else {
        return $c->status(404);
    }

    $c->log->debug('Looking up device '.$identifier.' for user '.$c->stash('user_id'));

    # fetch for device existence, id and location in one query
    my $device_check = $rs
        ->search(undef, { join => 'device_location' })
        ->add_columns([
            'id',
            { exists => \1 },
            { has_location => \'device_location.rack_id is not null' },
        ])
        ->hri
        ->single;

    # if the device doesn't exist, we can bail out right now
    if (not $device_check->{exists}) {
        $c->log->debug('Failed to find device '.$identifier);
        return $c->status(404);
    }

    my $device_id = $device_check->{id};
    $c->stash('device_id', $device_id);

    if ($c->is_system_admin) {
        $c->log->debug('User has system admin privileges to access device '.$device_id);
    }
    elsif ($device_check->{has_location}) {
        # if no minimum role was specified, use a heuristic:
        # HEAD, GET requires 'ro'; everything else (for now) requires 'rw'
        my $method = $c->req->method;
        my $requires_role = $c->stash('require_role') //
            (any { $method eq $_ } qw(HEAD GET)) ? 'ro'
          : (any { $method eq $_ } qw(POST PUT DELETE)) ? 'rw'
          : die 'need handling for '.$method.' method';

        if (not $c->db_devices->search({ 'device.id' => $device_id })
                ->user_has_role($c->stash('user_id'), $requires_role)) {
            $c->log->debug('User lacks the required role ('.$requires_role.') for device '.$device_id);
            return $c->status(403);
        }
    }
    else {
        # look for unlocated devices among those that have sent a device report proxied by a
        # relay using the user's credentials
        $c->log->debug('looking for device '.$device_id.' associated with relay reports');

        my $device_rs = $c->db_devices
            ->search({ 'device.id' => $device_id })
            ->devices_reported_by_user_relay($c->stash('user_id'));

        if (not $device_rs->exists) {
            $c->log->debug('User cannot access unlocated device '.$device_id);
            return $c->status(403);
        }
    }

    $c->log->debug('Found device id '.$device_id);

    # store the simplified query to access the device, now that we've confirmed the user has
    # the required role to access it.
    # No queries have been made yet, so you can add on more criteria or prefetches.
    $c->stash('device_rs', $c->db_devices->search_rs({ 'device.id' => $device_id }));

    return 1;
}

=head2 get

Retrieves details about a single device. Response uses the DetailedDevice json schema.

B<Note:> The results of this endpoint can be cached, but since the checksum is based only on
the device's last updated time, and not on any other components associated with it (disks,
network interfaces, location etc) it is only suitable for using to determine if a subsequent
device report has been submitted for this device. Updates to the device through other means may
not be reflected in the checksum.

=cut

sub get ($c) {
    # allow the (authenticated) client to cache the result based on updated time
    my $etag = Digest::MD5::md5_hex($c->stash('device_rs')->get_column('updated')->single);
    # TODO: this is really a weak etag. requires https://github.com/mojolicious/mojo/pull/1420
    return $c->status(304) if $c->is_fresh(etag => $etag);

    my ($device) = $c->stash('device_rs')
        ->prefetch([ { active_device_nics => 'device_neighbor' }, 'active_device_disks' ])
        ->order_by([ qw(iface_name active_device_disks.serial_number) ])
        ->all;

    my $device_location_rs = $c->stash('device_rs')
        ->related_resultset('device_location');

    # fetch rack, room and datacenter in one query
    my $rack = $device_location_rs
        ->related_resultset('rack')
        ->prefetch({ datacenter_room => 'datacenter' })
        ->add_columns({ rack_unit_start => 'device_location.rack_unit_start' })
        ->single;

    my $latest_report = $c->stash('device_rs')->latest_device_report->get_column('report')->single;

    my $detailed_device = +{
        $device->TO_JSON->%*,
        latest_report => $latest_report ? from_json($latest_report) : undef,
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
    /device?link=$link
    /device?$setting_key=$setting_value

Response uses the Devices json schema.

=cut

sub lookup_by_other_attribute ($c) {
    my $params = $c->validate_query_params('GetDeviceByAttribute');
    return if not $params;

    my ($key, $value) = $params->%*;
    $c->log->debug('looking up device by '.$key.' = '.$value);

    my $device_rs = $c->db_devices;
    if ($key eq 'hostname') {
        $device_rs = $device_rs->search({ 'device.'.$key => $value });
    }
    elsif ($key eq 'link') {
        # we do this instead of '? = any(links)' in order to take
        # advantage of the built-in GIN indexing on the @> operator
        $device_rs = $device_rs->search(\[ 'links @> array[?]', $value ]);
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
            ->search({ 'device_setting.name' => $key, value => $value })
            ->related_resultset('device');
    }

    # save ourselves a more expensive query if there are no matches
    if (not $device_rs->exists) {
        $c->log->debug('Failed to find devices matching '.$key.'='.$value);
        return $c->status(404);
    }

    # Now filter the results by what the user is permitted to see. Depending on the size of the
    # initial resultset, this could be slow!
    if (not $c->is_system_admin) {
        my $device_in_workspace_or_build_rs = $device_rs
            ->with_user_role($c->stash('user_id'), 'ro');

        my $device_via_relay_rs = $device_rs
            ->devices_without_location
            ->devices_reported_by_user_relay($c->stash('user_id'));
        $device_rs = $device_in_workspace_or_build_rs->union($device_via_relay_rs);
    }

    my @devices = $device_rs
        ->prefetch('device_location')
        ->order_by('device.created')
        ->all;

    if (not @devices) {
        $c->log->debug('User cannot access requested device(s)');
        return $c->status(403);
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
            join => { device_location => { rack => { datacenter_room => 'datacenter' } } },
        })
        ->hri
        ->all;

    my $ipmi = delete $device->{ipmi_mac_ip};
    $device->{ipmi} = $ipmi ? { mac => $ipmi->[0], ip => $ipmi->[1] } : undef;

    $c->status(200, $device);
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

Gets just the device's phase. Response uses the DevicePhase json schema.

=cut

sub get_phase ($c) {
    return $c->status(200, $c->stash('device_rs')->columns([qw(id phase)])->hri->single);
}

=head2 get_sku

Gets just the device's hardware_product_id and sku. Response uses the DeviceSku json schema.

=cut

sub get_sku($c) {
    my $rs = $c->stash('device_rs')
        ->search(undef, { join => 'hardware_product' })
        ->columns({
            id => 'device.id',
            hardware_product_id => 'hardware_product.id',
            sku => 'hardware_product.sku',
        });
    return $c->status(200, $rs->hri->single);
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

=head2 add_links

Appends the provided link(s) to the device record.

=cut

sub add_links ($c) {
    my $input = $c->validate_request('DeviceLinks');
    return if not $input;

    # only perform the update if not all links are already present
    $c->stash('device_rs')
        ->search(\[ 'not(links @> ?)', [{},$input->{links}] ])
        ->update({
            links => \[ 'array_cat_distinct(links,?)', [{},$input->{links}] ],
            updated => \'now()',
        });

    $c->status(303, '/device/'.$c->stash('device_id'));
}

=head2 remove_links

Removes all links from the device record.

=cut

sub remove_links ($c) {
    $c->stash('device_rs')
        ->search({ links => { '!=' => '{}' } })
        ->update({ links => '{}', updated => \'now()' });
    $c->status(204);
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
