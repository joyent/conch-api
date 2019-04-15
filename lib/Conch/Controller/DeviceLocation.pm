package Conch::Controller::DeviceLocation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Try::Tiny;

=pod

=head1 NAME

Conch::Controller::DeviceLocation

=head1 METHODS

=head2 get

Retrieves location data for the current device.

Response uses the DeviceLocation json schema.

=cut

sub get ($c) {
    my $device_location_rs = $c->stash('device_rs')
        ->related_resultset('device_location');

    my $rack = $device_location_rs
        ->related_resultset('rack')
        ->prefetch({ datacenter_room => 'datacenter' })
        ->add_columns({ rack_unit_start => 'device_location.rack_unit_start' })
        ->single;

    return $c->status(409, { error =>
        'Device '.$c->stash('device_id').' is not assigned to a rack'
    }) unless $rack;

    my $location = +{
        rack => $rack,
        rack_unit_start => $rack->get_column('rack_unit_start'),
        datacenter_room => $rack->datacenter_room,
        datacenter => $rack->datacenter_room->datacenter,
        target_hardware_product => $device_location_rs->target_hardware_product->single,
    };

    $c->status(200, $location);
}

=head2 set

Sets the location for a device, given a valid rack id and rack unit

=cut

sub set ($c) {
    my $input = $c->validate_input('DeviceLocationUpdate');
    return if not $input;

    my $device_id = $c->stash('device_id');

    my $error;
    try {
        $c->db_device_locations->assign_device_location($device_id, $input->@{qw(rack_id rack_unit)});
    }
    catch {
        chomp($error = $_);
    };

    return $c->status(409, { error => $error }) if $error;

    $c->status(303);
    $c->redirect_to($c->url_for('/device/'.$device_id.'/location'));
}

=head2 delete

Deletes the location data for a device, provided it has been assigned to a location

=cut

sub delete ($c) {
    return $c->status(409, { error => 'Device '.$c->stash('device_id').' is not assigned to a rack' })
        # 0 rows updated -> 0E0 which is boolean truth, not false
        unless $c->stash('device_rs')->related_resultset('device_location')->delete > 0;

    $c->status(204);
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
# vim: set ts=4 sts=4 sw=4 et :
