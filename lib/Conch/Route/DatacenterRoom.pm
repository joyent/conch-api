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

    my $with_datacenter_room = $room->under('/:datacenter_room_id_or_alias')
        ->to('#find_datacenter_room');

    # GET /room/:datacenter_room_id_or_alias
    $with_datacenter_room->get('/')->to('#get_one');
    # POST /room/:datacenter_room_id_or_alias
    $with_datacenter_room->post('/')->to('#update');
    # DELETE /room/:datacenter_room_id_or_alias
    $with_datacenter_room->delete('/')->to('#delete');

    # GET /room/:datacenter_room_id_or_alias/racks
    $with_datacenter_room->get('/racks')->to('#racks');

    # GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name
    $with_datacenter_room->get('/rack/#rack_id_or_name')->to('#find_rack');
}

1;
__END__

=pod

All routes require authentication.

=head3 C<GET /room>

=over 4

=item * Requires system admin authorization

=item * Response: F<response.yaml#/definitions/DatacenterRoomsDetailed>

=back

=head3 C<POST /room>

=over 4

=item * Requires system admin authorization

=item * Request: F<request.yaml#/definitions/DatacenterRoomCreate>

=item * Response: Redirect to the created room

=back

=head3 C<GET /room/:datacenter_room_id_or_alias>


=over 4

=item * Requires system admin authorization

=item * Response: F<response.yaml#/definitions/DatacenterRoomDetailed>

=back

=head3 C<POST /room/:datacenter_room_id_or_alias>

=over 4

=item * Requires system admin authorization

=item * Request: F<request.yaml#/definitions/DatacenterRoomUpdate>

=item * Response: Redirect to the updated room

=back

=head3 C<DELETE /room/:datacenter_room_id_or_alias>

=over 4

=item * Requires system admin authorization

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /room/:datacenter_room_id_or_alias/racks>

=over 4

=item * Requires system admin authorization

=item * Response: F<response.yaml#/definitions/Racks>

=back

=head3 C<GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name>

=over 4

=item * Requires system admin authorization

=item * Response: F<response.yaml#/definitions/Rack>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
