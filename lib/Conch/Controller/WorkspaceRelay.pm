package Conch::Controller::WorkspaceRelay;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::WorkspaceRelay

=head1 METHODS

=head2 list

List all relays located in the indicated workspace and sub-workspaces beneath it.
Note that this information is only accurate if the device the relay(s) reported
have not since been moved to another location.

Use C<?active_minutes=X> to constrain results to those updated in the last X minutes.

Response uses the WorkspaceRelays json schema.

=cut

sub list ($c) {
    my $params = $c->validate_query_params('WorkspaceRelays');
    return if not $params;

    my $workspace_racks = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->get_column('id');

    # this is a bit gross, as we need to find all relays' last locations before we can
    # constrain down to locations within this workspace
    my $relays_rs = $c->db_device_relay_connections
        ->search(
            $params->{active_minutes}
                ? { last_seen =>
                    { '>=' => \[ 'now() - ?::interval', $params->{active_minutes}.' minutes' ] } }
                : undef,
            {
                '+select' => [{
                    '' => \'row_number() over (partition by relay_id order by last_seen desc)',
                    -as => 'result_num',
                }],
            },
        )
        ->as_subselect_rs
        ->search(
            {
                rack_id => { -in => $workspace_racks->as_query },
                result_num => 1,
            },
            {
                prefetch => 'relay',
                join => { device => { device_location => {
                            rack => [ qw(rack_role datacenter_room) ] } } },
                columns => {
                    last_seen => 'device_relay_connection.last_seen',
                    rack_id => 'device_location.rack_id',
                    rack_name => 'rack.name',
                    rack_unit_start => 'device_location.rack_unit_start',
                    rack_role_name => 'rack_role.name',
                    az => 'datacenter_room.az',
                    num_devices => $c->db_relays->correlate('device_relay_connections')->count_rs->as_query,
                },
            },
        )
        ->order_by('relay.last_seen');

    my @relays = map {
        my %cols = $_->get_columns;
        +{
            $_->relay->TO_JSON->%*,
            location => +{ %cols{qw(rack_id rack_name rack_unit_start rack_role_name az)} },
            num_devices => $cols{num_devices},
        }
    } $relays_rs->all;

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
        ->search_related('device',
            { relay_id => $c->stash('relay_id') }, { join => 'device_relay_connections' })
        ->with_device_location
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
