=pod

=head1 NAME

Conch::Class::DatacenterRack

=head1 METHODS

=cut

package Conch::Class::DatacenterRack;
use Mojo::Base -base, -signatures;

=head2 id

=head2 name

=head2 role_name

=head2 datacenter_room_id

=head2 slots

List of available slots defined by the rack layout

=cut

has [qw( id name role_name datacenter_room_id slots)];

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
