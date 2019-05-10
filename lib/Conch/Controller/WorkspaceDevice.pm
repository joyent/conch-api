package Conch::Controller::WorkspaceDevice;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';
use List::Util 'none';

=pod

=head1 NAME

Conch::Controller::WorkspaceDevice

=head1 METHODS

=head2 list

Get a list of all active devices in the current workspace (as specified by :workspace_id in the
path).

Supports these query parameters to constrain results (which are ANDed together, not ORed):

    graduated=T     only devices with graduated set
    graduated=F     only devices with graduated not set
    validated=T     only devices with validated set
    validated=F     only devices with validated not set
    health=<value>  only devices with health matching provided value (case-insensitive)
    active=1        only devices last seen within 5 minutes (FIXME: ambiguous name)
    ids_only=1      only return device ids, not full data

Response uses the Devices json schema, or DeviceIds iff C<ids_only=1>.

=cut

sub list ($c) {
    my $devices_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->related_resultset('device_locations')
        ->related_resultset('device')
        ->active
        ->prefetch('device_location')
        ->order_by('device.created');

    my $params = $c->req->query_params->to_hash;

    $devices_rs = $devices_rs->search({ graduated => { '!=' => undef } })
        if defined $params->{graduated} and uc $params->{graduated} eq 'T';

    $devices_rs = $devices_rs->search({ graduated => undef })
        if defined $params->{graduated} and uc $params->{graduated} eq 'F';

    $devices_rs = $devices_rs->search({ validated => { '!=' => undef } })
        if defined $params->{validated} and uc $params->{validated} eq 'T';

    $devices_rs = $devices_rs->search({ validated => undef })
        if defined $params->{validated} and uc $params->{validated} eq 'F';

    if (defined $params->{health}) {
        # requested health parameter is incompatible with device_health_enum
        return $c->status(200, [])
            if none { lc $params->{health} eq $_ } $devices_rs->result_source->column_info('health')->{extra}{list}->@*;

        $devices_rs = $devices_rs->search({ health => lc $params->{health} });
    }

    $devices_rs = $devices_rs->search({ last_seen => { '>' => \q{now() - interval '300 second'}} })
        if defined $params->{active};

    $devices_rs = $devices_rs->get_column('id')
        if defined $params->{ids_only};

    my @devices = $devices_rs->all;

    $c->status(200, \@devices);
}

=head2 get_pxe_devices

Response uses the WorkspaceDevicePXEs json schema.

=cut

sub get_pxe_devices ($c) {
    my $device_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->related_resultset('device_locations')
        ->as_subselect_rs  # avoids earlier device_locations from interfering with subqueries
        ->related_resultset('device')
        ->active;

    my @devices = $device_rs->search(undef,
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
        ->order_by('device.created')
        ->hri
        ->all;

    foreach my $device (@devices) {
        # DBIC collapse is inconsistent here with handling the lack of a datacenter_room->datacenter
        $device->{location}{datacenter} = undef
            if $device->{location} and not defined $device->{location}{datacenter}{name};

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

    my %switch_aliases = map +($_ => 1), $c->config->{switch_aliases}->@*;
    my %storage_aliases = map +($_ => 1), $c->config->{storage_aliases}->@*;
    my %compute_aliases = map +($_ => 1), $c->config->{compute_aliases}->@*;

    my @counts = $workspace
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->related_resultset('device_locations')
        ->related_resultset('device')
        ->active
        ->search(
            undef,
            {
                columns => { alias => 'hardware_product.alias', health => 'device.health' },
                select => [{ count => '*', -as => 'count' }],
                group_by => [ 'hardware_product.alias', 'device.health' ],
                order_by => [ 'hardware_product.alias', 'device.health' ],
                join => 'hardware_product',
            },
        )->hri->all;

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
            if ($circ{$_->{alias}}{health}{uc $_->{health}}) {
                $circ{$_->{alias}}{health}{uc $_->{health}} += $_->{count};
            }
            else {
                $circ{$_->{alias}}{health}{uc $_->{health}} = $_->{count};
            }
        }
        else {
            $circ{$_->{alias}} = {
                count => $_->{count},
                health => {
                    FAIL => 0,
                    PASS => 0,
                    UNKNOWN => 0,
                }
            };
            $circ{$_->{alias}}{health}{uc $_->{health}} = $_->{count};
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
