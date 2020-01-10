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

Chainable action that uses the C<device_id>, C<device_serial_number> or
C<device_id_or_serial_number> provided in the stash (usually via the request URL) to look up a
device, and stashes the query to get to it in C<device_rs>.

If C<require_role> is provided, it is used as the minimum required role for the user to
continue; otherwise the user must be a registered relay user or a system admin.

If C<phase_earlier_than> is provided, C<409 CONFLICT> is returned if the device is in the
provided phase (or later).

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
        $c->log->error('missing identifier for #find_device');
        return $c->status(404);
    }

    $c->log->debug('Looking up device '.$identifier.' for user '.$c->stash('user_id'));
    my $device_id = $rs->get_column('id')->single;

    # if the device id cannot be fetched, we can bail out right now
    if (not $device_id) {
        $c->log->debug('Could not find device '.$identifier);
        return $c->status(404);
    }

    CHECK_ACCESS: {
        if ($c->is_system_admin) {
            $c->log->debug('User has system admin privileges for device '.$device_id);
            last CHECK_ACCESS;
        }

        # if no minimum role was specified, use a heuristic:
        # HEAD, GET requires 'ro'; everything else (for now) requires 'rw'
        my $method = $c->req->method;
        my $requires_role = $c->stash('require_role') //
           ((any { $method eq $_ } qw(HEAD GET)) ? 'ro'
          : (any { $method eq $_ } qw(POST PUT DELETE)) ? 'rw'
          : die 'need handling for '.$method.' method');

        last CHECK_ACCESS if $requires_role eq 'none';

        if ($c->db_devices->search({ 'device.id' => $device_id })
                ->user_has_role($c->stash('user_id'), $requires_role)) {
            $c->log->debug('User has '.$requires_role.' access to device '.$device_id.' via role entry');
            last CHECK_ACCESS;
        }

        # look for devices among those that have sent a device report proxied by a relay
        # using the user's credentials: for historical reasons we consider this equivalent to
        # 'admin' access (but it really should be 'ro')
        $c->log->debug('looking for device '.$device_id.' associated with relay reports');
        my $device_rs = $c->db_devices
            ->search({ 'device.id' => $device_id })
            ->devices_reported_by_user_relay($c->stash('user_id'));

        if ($device_rs->exists) {
            $c->log->debug('User has de facto '.$requires_role.' access to device '.$device_id.' via relay connection');
            last CHECK_ACCESS;
        }

        $c->log->debug('User lacks the required role ('.$requires_role.') for device '.$device_id);
        return $c->status(403);
    }

    $c->log->debug('Found device id '.$device_id);

    # store the simplified query to access the device, now that we've confirmed the user has
    # the required role to access it.
    # No queries have been made yet, so you can add on more criteria or prefetches.
    $c->stash('device_id', $device_id);
    $c->stash('device_rs', $c->db_devices->search_rs({ 'device.id' => $device_id }));

    if (my $bad_phase = $c->req->query_params->param('phase_earlier_than')
            // $c->stash('phase_earlier_than')) {
        my $phase = $c->stash('device_rs')->get_column('phase')->single;
        if (Conch::DB::Result::Device->phase_cmp($phase, $bad_phase) >= 0) {
            $c->res->headers->location($c->url_for('/device/'.$device_id.'/links'));
            return $c->status(409, { error => 'device is in the '.$phase.' phase' });
        }
    }

    $c->res->headers->location('/device/'.$device_id);
    return 1;
}

=head2 get

Retrieves details about a single device. Response uses the DetailedDevice json schema.

B<Note:> The results of this endpoint can be cached, but since the checksum is based only on
the device's last updated time, and not on any other components associated with it (disks,
network interfaces, location etc) it is only suitable for using to determine if a subsequent
device report has been submitted for this device (or columns directly on the device have been
updated). Updates to the device through other means (such as changing its location) may not be
reflected in the checksum.

=cut

sub get ($c) {
    # allow the (authenticated) client to cache the result based on updated time
    my $etag = Digest::MD5::md5_hex($c->stash('device_rs')->get_column('updated')->single);
    # TODO: this is really a weak etag. requires https://github.com/mojolicious/mojo/pull/1420
    return $c->status(304) if $c->is_fresh(etag => $etag);

    my $device = $c->stash('device_rs')->with_sku->with_build_name->single;
    my $latest_report = $c->stash('device_rs')->latest_device_report->get_column('report')->single;

    my $detailed_device = +{
        $device->TO_JSON->%*,
        latest_report => $latest_report ? from_json($latest_report) : undef,
    };

    if ($device->phase_cmp('production') < 0) {
        $detailed_device->{location} = $c->stash('device_rs')->location_data->single;
        undef $detailed_device->{location} if not $detailed_device->{location}{rack};

        $detailed_device->{nics} = [ map {
            my $device_nic = $_;
            my $device_neighbor = $device_nic->device_neighbor;
            +{
                (map +($_ => $device_nic->$_), qw(mac iface_name iface_type iface_vendor)),
                (map +($_ => $device_neighbor && $device_neighbor->$_), qw(peer_mac peer_port peer_switch)),
            }
        }
            $c->stash('device_rs')
                ->related_resultset('device_nics')
                ->active
                ->prefetch('device_neighbor')
                ->order_by('iface_name')
                ->all
        ];

        $detailed_device->{disks} = [
            $c->stash('device_rs')
                ->related_resultset('device_disks')
                ->active
                ->order_by('slot')
                ->all
        ];
    }

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
            {
                # production devices do not consider interface data to be canonical
                $device_rs->current_source_alias.'.phase' => { '<' => \[ '?::device_phase_enum', 'production' ] },
                'device_nics.'.$key => $value,
            },
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
        $c->log->debug('Could not find devices matching '.$key.'='.$value);
        return $c->status(404);
    }

    # Now filter the results by what the user is permitted to see. Depending on the size of the
    # initial resultset, this could be slow!
    if (not $c->is_system_admin) {
        my $device_in_workspace_or_build_rs = $device_rs
            ->with_user_role($c->stash('user_id'), 'ro');

        my $device_via_relay_rs = $device_rs
            ->devices_reported_by_user_relay($c->stash('user_id'));
        $device_rs = $device_in_workspace_or_build_rs->union($device_via_relay_rs);
    }

    my @devices = $device_rs
        ->with_device_location
        ->with_sku
        ->with_build_name
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

    $device_rs = $device_rs
        ->location_data('location')
        ->add_columns({
            id => 'device.id',
            phase => 'device.phase',
            # pxe = the first (sorted by name) interface that is status=up
            'pxe.mac' => $device_rs->correlate('device_nics')->nic_pxe->as_query,
            # ipmi = the (newest) interface named ipmi1.
            ipmi_mac_ip => $device_rs->correlate('device_nics')->nic_ipmi->as_query,
        });

    my ($device) = $device_rs->all;
    undef $device->{location} if not $device->{location}{rack};

    delete $device->{location}
        if Conch::DB::Result::Device->phase_cmp($device->{phase}, 'production') >= 0;

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

    $device->set_columns($input);
    return $c->status(204) if not $device->is_changed;

    $device->update({ updated => \'now()' });
    $c->log->debug('Set the asset tag for device '.$device->id.' to '.($input->{asset_tag} // 'null'));

    $c->status(303);
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

    $c->status(303);
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

    my $device = $c->stash('device_rs')->single;

    $device->set_columns($input);
    return $c->status(204) if not $device->is_changed;

    $device->update({ updated => \'now()' });
    $c->log->debug('Set the phase for device '.$c->stash('device_id').' to '.$input->{phase});

    $c->status(303);
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

    $c->status(303);
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

=head2 set_build

Moves the device to a new build.

Also requires read/write access to the old and new builds.

=cut

sub set_build ($c) {
    my $input = $c->validate_request('DeviceBuild');
    return if not $input;

    my $device = $c->stash('device_rs')->single;
    return $c->status(204) if $device->build_id and $device->build_id eq $input->{build_id};

    if (not $c->is_system_admin) {
        if ($device->build_id and not $device->related_resultset('build')->user_has_role($c->stash('user_id'), 'rw')) {
            $c->log->debug('User lacks the required role (rw) for existing build '.$device->build_id);
            return $c->status(403);
        }

        if (not $c->db_builds->search({ 'build.id' => $input->{build_id} })->user_has_role($c->stash('user_id'), 'rw')) {
            $c->log->debug('User lacks the required role (rw) for new build '.$input->{build_id});
            return $c->status(403);
        }
    }

    $device->update({ build_id => $input->{build_id}, updated => \'now()' });
    $c->status(303);
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
