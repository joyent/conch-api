package Conch::Controller::WorkspaceRelay;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::WorkspaceRelay

=head1 METHODS

=head2 list

List all relays located in the current workspace (as specified by :workspace_id in the path)
or sub-workspaces beneath it.

Use C<?active_within=X> to constrains results to those updated in the last X minutes.

Response uses the WorkspaceRelays json schema.

=cut

sub list ($c) {
    my $active_minutes = $c->req->query_params->param('active_within');

    my $latest_relay_connections = $c->db_device_relay_connections
        ->search(
            undef,
            {
                '+select' => [{
                    '' => \'row_number() over (partition by relay_id order by last_seen desc)',
                    -as => 'result_num',
                }],
            },
        )
        ->as_subselect_rs
        ->search({ result_num => 1 })
        ->order_by('last_seen');

    my $me = $latest_relay_connections->current_source_alias;

    $latest_relay_connections = $latest_relay_connections->search({
        $me.'.last_seen' => { '>=' => \[ 'now() - ?::interval', $active_minutes.' minutes' ] }
    }) if $active_minutes;

    my $num_devices_rs = $c->db_device_relay_connections->search(
        { $me.'_corr.relay_id' => { '=' => \"$me.relay_id" } },
        { alias => ${me}.'_corr' },
    )->count_rs;

    my $workspace_racks = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->get_column('id');

    my $workspace_relays_with_location = $latest_relay_connections
        ->search(
            { rack_id => { -in => $workspace_racks->as_query } },
            {
                prefetch => 'relay',
                join => { device => { device_location => {
                            rack => [ 'rack_role', 'datacenter_room' ] } } },
                '+columns' => {
                    rack_id => 'device_location.rack_id',
                    rack_name => 'rack.name',
                    rack_unit_start => 'device_location.rack_unit_start',
                    role_name => 'rack_role.name',
                    az => 'datacenter_room.az',
                    num_devices => $num_devices_rs->as_query,
                },
            },
        );

    my @relays = map {
        my $connection = $_;
        my %cols = $connection->get_columns;
        +{
            $connection->relay->TO_JSON->%*,
            location => +{ %cols{qw(rack_id rack_name rack_unit_start role_name az)} },
            last_seen => $connection->last_seen,
            num_devices => $cols{num_devices},
        }
    } $workspace_relays_with_location->all;

    $c->log->debug('Found '.scalar(@relays).' relays in workspace '.$c->stash('workspace_id'));
    $c->status(200, \@relays);
}

=head2 get_relay_devices

Returns all the devices that have been reported by the provided relay that are located within
this workspace. (It doesn't matter if the relay itself was later moved to another workspace - we
just look at device locations.)

Response uses the Devices json schema.

=cut

sub get_relay_devices ($c) {
    my $devices_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->related_resultset('device_locations')
        ->related_resultset('device')
        ->active
        ->search({ relay_id => $c->stash('relay_id') }, { join => 'device_relay_connections' })
        ->prefetch('device_location')
        ->order_by('device.created');

    my @devices = $devices_rs->all;
    $c->status(200, \@devices);
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
