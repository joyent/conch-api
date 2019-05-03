package Conch::DB::ResultSet::DeviceNic;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::DeviceNic

=head1 DESCRIPTION

Interface to queries involving device network interfaces.

=head1 METHODS

=head2 nic_pxe

Returns a resultset which provides the MAC address of the relevant PXE network interface(s)
(the first-by-name interface whose state = 'up').

Suitable for embedding as a sub-query.

=cut

sub nic_pxe ($self) {
    my $me = $self->current_source_alias;
    $self
        ->search({ $me.'.state' => 'up' })
        ->active
        ->order_by($me.'.iface_name')
        ->rows(1)
        ->columns(['mac']);
}

=head2 nic_ipmi

Returns a resultset which provides the MAC address and IP address (as an arrayref) of the
network interface(s) named "ipmi1".

Suitable for embedding as a sub-query; post-processing will be required to extract the two
columns into the desired format.

=cut

sub nic_ipmi ($self) {
    my $me = $self->current_source_alias;
    my $ipmi_rs = $self
        ->search({ $me.'.iface_name' => 'ipmi1' })
        ->active
        ->columns({ '' => \'array[mac::text, host(ipaddr)]' });
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
