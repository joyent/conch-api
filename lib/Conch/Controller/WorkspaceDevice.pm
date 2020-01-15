package Conch::Controller::WorkspaceDevice;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::WorkspaceDevice

=head1 METHODS

=head2 get_all

Get a list of all devices in the indicated workspace.

Supports these query parameters to constrain results (which are ANDed together for the search,
not ORed):

    validated=1     only devices with validated set
    validated=0     only devices with validated not set
    health=<value>  only devices with health matching the provided value
        (can be used more than once to search for ANY of the specified health values)
    active_minutes=X  only devices last seen within X minutes
    ids_only=1      only return device ids, not full data
    serials_only=1  only return device serial numbers, not full data

Response uses the Devices json schema, or DeviceIds iff C<ids_only=1>, or DeviceSerials iff
C<serials_only=1>.

=cut

sub get_all ($c) {
    my $params = $c->validate_query_params('WorkspaceDevices');
    return if not $params;

    my $devices_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->related_resultset('device_locations')
        ->related_resultset('device')
        ->order_by([ map 'device_locations.'.$_, qw(rack_id rack_unit_start) ]);

    $devices_rs = $devices_rs->search({ validated => { '!=' => undef } })
        if $params->{validated};

    $devices_rs = $devices_rs->search({ validated => undef })
        if defined $params->{validated} and not $params->{validated};

    $devices_rs = $devices_rs->search({ health => $params->{health} }) if $params->{health};

    $devices_rs = $devices_rs->search({ last_seen => { '>' => \[ 'now() - ?::interval', $params->{active_minutes}.' minutes' ] } })
        if $params->{active_minutes};

    $devices_rs = $params->{ids_only} ? $devices_rs->get_column('id')
        : $params->{serials_only} ? $devices_rs->get_column('serial_number')
        : $devices_rs->with_device_location->with_sku->with_build_name;

    my @devices = $devices_rs->all;

    $c->status(200, \@devices);
}

=head2 get_pxe_devices

Response uses the WorkspaceDevicePXEs json schema.

=cut

sub get_pxe_devices ($c) {
    # production devices do not consider location, interface data to be canonical
    my $bad_phase = $c->req->query_params->param('phase_earlier_than') // 'production';

    my $rack_ids_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->get_column('rack_id')
        ->as_query;

    my @devices = $c->db_devices
        ->search(
            # production devices do not consider location data to be canonical
            $bad_phase ? { 'device.phase' => { '<' => \[ '?::device_phase_enum', $bad_phase ] } } : ())
        ->location_data('location')
        ->add_columns({
            id => 'device.id',
            phase => 'device.phase',
            # pxe = the first (sorted by name) interface that is status=up
            'pxe.mac' => $c->db_devices->correlate('device_nics')->nic_pxe->as_query,
            # ipmi = the (newest) interface named ipmi1.
            ipmi_mac_ip => $c->db_devices->correlate('device_nics')->nic_ipmi->as_query,
        })
        ->search({ 'rack.id' => { -in => $rack_ids_rs } })
        ->order_by('device.created')
        ->hri
        ->all;

    foreach my $device (@devices) {
        delete $device->{location}
            if Conch::DB::Result::Device->phase_cmp($device->{phase}, 'production') >= 0;

        my $ipmi = delete $device->{ipmi_mac_ip};
        $device->{ipmi} = $ipmi ? { mac => $ipmi->[0], ip => $ipmi->[1] } : undef;
    }

    $c->status(200, \@devices);
}

=head2 device_totals

Ported from 'conch-stats'.

Response uses the 'DeviceTotals' and 'DeviceTotalsCirconus' json schemas.
Add '.circ' to the end of the URL to select the data format customized for Circonus.

Note that this is an unauthenticated endpoint.

=cut

sub device_totals ($c) {
    my $workspace_param = $c->stash('workspace');

    my $workspace;
    if ($workspace_param =~ /^name\=(.*)$/) {
        $workspace = $c->db_workspaces->find({ name => $1 }, { key => 'workspace_name_key' });
    }
    elsif (is_uuid($workspace_param)) {
        $workspace = $c->db_workspaces->find($workspace_param);
    }
    return $c->reply->not_found if not $workspace;

    my %switch_aliases = map +($_ => 1), ($c->app->config('switch_aliases')//{})->@*;
    my %storage_aliases = map +($_ => 1), ($c->app->config('storage_aliases')//{})->@*;
    my %compute_aliases = map +($_ => 1), ($c->app->config('compute_aliases')//{})->@*;

    my @counts = $workspace
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->related_resultset('device_locations')
        ->search_related('device', undef, { join => 'hardware_product' })
        ->columns({
            alias => 'hardware_product.alias',
            health => 'device.health',
            count => { count => '*' },
        })
        ->group_by([ qw(hardware_product.alias device.health) ])
        ->order_by([ qw(hardware_product.alias device.health) ])
        ->hri->all;

    my @switch_counts = grep $switch_aliases{$_->{alias}}, @counts;
    my @server_counts = grep !$switch_aliases{$_->{alias}}, @counts;
    my @storage_counts = grep $storage_aliases{$_->{alias}}, @counts;
    my @compute_counts = grep $compute_aliases{$_->{alias}}, @counts;

    my %circ;

    for (@storage_counts) {
        $circ{storage}{count} += $_->{count};
    }

    for (@compute_counts) {
        $circ{compute}{count} += $_->{count};
    }

    for (@counts) {
        if ($circ{$_->{alias}}) {
            $circ{$_->{alias}}{count} += $_->{count};
            if ($circ{$_->{alias}}{health}{$_->{health}}) {
                $circ{$_->{alias}}{health}{$_->{health}} += $_->{count};
            }
            else {
                $circ{$_->{alias}}{health}{$_->{health}} = $_->{count};
            }
        }
        else {
            $circ{$_->{alias}} = {
                count => $_->{count},
                health => {
                    fail => 0,
                    pass => 0,
                    unknown => 0,
                }
            };
            $circ{$_->{alias}}{health}{$_->{health}} = $_->{count};
        }
    }

    return $c->respond_to(
        any => { json => {
            all      => \@counts,
            servers  => \@server_counts,
            switches => \@switch_counts,
            storage  => \@storage_counts,
            compute  => \@compute_counts,
        }},
        circ => { json => \%circ },
    );
};

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
