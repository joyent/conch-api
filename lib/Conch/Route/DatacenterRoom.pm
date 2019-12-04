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

    $room = $room->to({ controller => 'datacenter_room' });

    my $room_with_system_admin = $room->require_system_admin;

    # GET /room
    $room_with_system_admin->get('/')->to('#get_all');
    # POST /room
    $room_with_system_admin->post('/')->to('#create');

    my $with_datacenter_room_ro = $room->under('/:datacenter_room_id_or_alias')
        ->to('#find_datacenter_room', require_role => 'ro');

    my $with_datacenter_room_system_admin =
        $room_with_system_admin->under('/:datacenter_room_id_or_alias')
            ->to('#find_datacenter_room');

    # GET /room/:datacenter_room_id_or_alias
    $with_datacenter_room_ro->get('/')->to('#get_one');
    # POST /room/:datacenter_room_id_or_alias
    $with_datacenter_room_system_admin->post('/')->to('#update');
    # DELETE /room/:datacenter_room_id_or_alias
    $with_datacenter_room_system_admin->delete('/')->to('#delete');

    # GET /room/:datacenter_room_id_or_alias/rack
    $with_datacenter_room_ro->get('/rack')->to('#racks');

    # GET    /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name
    # DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name
    # GET    /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layouts
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layouts
    # GET    /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment
    # DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/phase?rack_only=<0|1>
    Conch::Route::Rack->one_rack_routes(
        $room->under('/:datacenter_room_id_or_alias')
            ->to('#find_datacenter_room', require_role => 'none')
            ->any('/rack')->to(require_role => undef)
    );
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

=item * User requires system admin authorization, or the read-only role on a rack located in
the room

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

=head3 C<GET /room/:datacenter_room_id_or_alias/rack>

=over 4

=item * User requires system admin authorization, or the read-only role on a rack located in
the room (in which case data returned is restricted to those racks)

=item * Response: F<response.yaml#/definitions/Racks>

=back

=head3 C<GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name>

=over 4

=item * User requires the read-only role on the rack

=item * Response: F<response.yaml#/definitions/Rack>

=back

=head3 C<POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name>

=over 4

=item * User requires the read/write role on the rack

=item * Request: F<request.yaml#/definitions/RackUpdate>

=item * Response: Redirect to the updated rack

=back

=head3 C<DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name>

=over 4

=item * Requires system admin authorization

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layouts>

=over 4

=item * User requires the read-only role on the rack

=item * Response: F<response.yaml#/definitions/RackLayouts>

=back

=head3 C<POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layouts>

=over 4

=item * User requires the read/write role on the rack

=item * Request: F<request.yaml#/definitions/RackLayouts>

=item * Response: Redirect to the rack's layouts

=back

=head3 C<GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment>

=over 4

=item * User requires the read-only role on the rack

=item * Response: F<response.yaml#/definitions/RackAssignments>

=back

=head3 C<POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment>

=over 4

=item * User requires the read/write role on the rack

=item * Request: F<request.yaml#/definitions/RackAssignmentUpdates>

=item * Response: Redirect to the updated rack assignment

=back

=head3 C<DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment>

This method requires a request body.

=over 4

=item * User requires the read/write role on the rack

=item * Request: F<request.yaml#/definitions/RackAssignmentDeletes>

=item * Response: C<204 NO CONTENT>

=back

=head3 C<< POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/phase?rack_only=<0|1> >>

The query parameter C<rack_only> (defaults to C<0>) specifies whether to update
only the rack's phase, or all the rack's devices' phases as well.

=over 4

=item * User requires the read/write role on the rack

=item * Request: F<request.yaml#/definitions/RackPhase>

=item * Response: Redirect to the updated rack

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
