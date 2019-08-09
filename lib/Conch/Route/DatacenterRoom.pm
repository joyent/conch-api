package Conch::Route::DatacenterRoom;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::DatacenterRoom

=head1 METHODS

=head2 routes

Sets up the routes for /room:

=cut

sub routes {
    my $class = shift;
    my $room = shift;   # secured, under /room

    $room = $room->require_system_admin->to({ controller => 'datacenter_room' });

    # GET /room
    $room->get('/')->to('#get_all');
    # POST /room
    $room->post('/')->to('#create');

    my $with_datacenter_room = $room->under('/<datacenter_room_id:uuid>')
        ->to('#find_datacenter_room');

    # GET /room/:datacenter_room_id
    $with_datacenter_room->get('/')->to('#get_one');
    # POST /room/:datacenter_room_id
    $with_datacenter_room->post('/')->to('#update');
    # DELETE /room/:datacenter_room_id
    $with_datacenter_room->delete('/')->to('#delete');
    # GET /room/:datacenter_room_id/racks
    $with_datacenter_room->get('/racks')->to('#racks');
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<GET /room>

=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/DatacenterRoomsDetailed

=back

=head3 C<POST /room>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/DatacenterRoomCreate

=item * Response: Redirect to the created room

=back

=head3 C<GET /room/:datacenter_room_id>


=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/DatacenterRoomDetailed

=back

=head3 C<POST /room/:datacenter_room_id>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/DatacenterRoomUpdate

=item * Response: Redirect to the updated room

=back

=head3 C<DELETE /room/:datacenter_room_id>

=over 4

=item * Requires system admin authorization

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /room/:datacenter_room_id/racks>

=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/Racks

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
