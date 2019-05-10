package Conch::Controller::DeviceInterface;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use List::Util 'none';

=pod

=head1 NAME

Conch::Controller::Device

=head1 METHODS

=head2 find_device_interface

Chainable action that looks up the device interface by its id or name.

=cut

sub find_device_interface ($c) {
    my $interface_name = $c->stash('interface_name');

    $c->log->debug('Looking up interface '.$interface_name
        .' for device_id '.$c->stash('device_id'));

    my $nic_rs = $c->stash('device_rs')
        ->search_related('device_nics', { iface_name => $interface_name })
        ->active;
    if (not $nic_rs->exists) {
        $c->log->debug("Failed to find interface $interface_name for device ".$c->stash('device_id'));
        return $c->status(404);
    }

    $c->stash('device_interface_rs', scalar $nic_rs);

    return 1;
}

=head2 get_one_field

Retrieves the value of the specified device_nic field for the specified device interface.

Response uses the DeviceNicField json schema.

=cut

sub get_one_field ($c) {
    my $field = $c->stash('field');
    my $rs = $c->stash('device_interface_rs');
    return $c->status(200, { $field => $rs->get_column($field)->single });
}

=head2 get_one

Retrieves all device_nic fields for the specified device interface.

Response uses the DeviceNic json schema.

=cut

sub get_one ($c) {
    return $c->status(200, $c->stash('device_interface_rs')->single);
}

=head2 get_all

Retrieves all device_nic records for the specified device.

Response uses the DeviceNics json schema.

=cut

sub get_all ($c) {
    my $rs = $c->stash('device_rs')->related_resultset('device_nics')->active;
    return $c->status(200, [ $rs->all ]);
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
