package Conch::Route::DatacenterRoom;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::DatacenterRoom

=head1 METHODS

=head2 routes

Sets up the routes for /room.

=cut

sub routes {
    my $class = shift;
    my $room = shift;   # secured, under /room

    $room = $room->to({ controller => 'datacenter_room' });

    my $room_with_system_admin = $room->require_system_admin;

    # GET /room
    $room_with_system_admin->get('/')->to('#get_all', response_schema => 'DatacenterRoomsDetailed');
    # POST /room
    $room_with_system_admin->post('/')->to('#create', request_schema => 'DatacenterRoomCreate');

    my $with_datacenter_room_ro = $room->under('/:datacenter_room_id_or_alias')
        ->to('#find_datacenter_room', require_role => 'ro');

    my $with_datacenter_room_system_admin =
        $room_with_system_admin->under('/:datacenter_room_id_or_alias')
            ->to('#find_datacenter_room');

    # GET /room/:datacenter_room_id_or_alias
    $with_datacenter_room_ro->get('/')->to('#get_one', response_schema => 'DatacenterRoomDetailed');
    # POST /room/:datacenter_room_id_or_alias
    $with_datacenter_room_system_admin->post('/')->to('#update', request_schema => 'DatacenterRoomUpdate');
    # DELETE /room/:datacenter_room_id_or_alias
    $with_datacenter_room_system_admin->delete('/')->to('#delete');

    # GET /room/:datacenter_room_id_or_alias/rack
    $with_datacenter_room_ro->get('/racks', sub { shift->status(308, 'get_room_racks') });
    $with_datacenter_room_ro->get('/rack', 'get_room_racks')->to('#racks', response_schema => 'Racks');

    # GET    /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name
    # DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name
    # GET    /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout
    # GET    /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment
    # DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/phase?rack_only=<0|1>
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/links>
    # DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/links>
    # GET    /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
    # POST   /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
    # DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
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

=head1 ROUTE ENDPOINTS

=head2 C<GET /room>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::DatacenterRoom/get_all>

=item * Response: F<response.yaml#/$defs/DatacenterRoomsDetailed>

=back

=head2 C<POST /room>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::DatacenterRoom/create>

=item * Request: F<request.yaml#/$defs/DatacenterRoomCreate>

=item * Response: C<201 Created>, plus Location header

=back

=head2 C<GET /room/:datacenter_room_id_or_alias>

=over 4

=item * User requires system admin authorization, or the read-only role on a rack located in
the room

=item * Controller/Action: L<Conch::Controller::DatacenterRoom/get_one>

=item * Response: F<response.yaml#/$defs/DatacenterRoomDetailed>

=back

=head2 C<POST /room/:datacenter_room_id_or_alias>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::DatacenterRoom/update>

=item * Request: F<request.yaml#/$defs/DatacenterRoomUpdate>

=item * Response: C<204 No Content>, plus Location header

=back

=head2 C<DELETE /room/:datacenter_room_id_or_alias>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::DatacenterRoom/delete>

=item * Response: C<204 No Content>

=back

=head2 C<GET /room/:datacenter_room_id_or_alias/rack>

=over 4

=item * User requires system admin authorization, or the read-only role on a rack located in
the room (in which case data returned is restricted to those racks)

=item * Controller/Action: L<Conch::Controller::DatacenterRoom/racks>

=item * Response: F<response.yaml#/$defs/Racks>

=back

=head2 C<GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name>

See L<Conch::Route::Rack/C<GET /rack/:rack_id_or_name>>.

=head2 C<POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name>

See L<Conch::Route::Rack/C<POST /rack/:rack_id_or_name>>.

=head2 C<DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name>

See L<Conch::Route::Rack/C<DELETE /rack/:rack_id_or_name>>.

=head2 C<GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout>

See L<Conch::Route::Rack/C<GET /rack/:rack_id_or_name/layout>>.

=head2 C<POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout>

See L<Conch::Route::Rack/C<POST /rack/:rack_id_or_name/layout>>.

=head2 C<GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment>

See L<Conch::Route::Rack/C<GET /rack/:rack_id_or_name/assignment>>.

=head2 C<POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment>

See L<Conch::Route::Rack/C<POST /rack/:rack_id_or_name/assignment>>.

=head2 C<DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment>

See L<Conch::Route::Rack/C<DELETE /rack/:rack_id_or_name/assignment>>.

=head2 C<< POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/phase?rack_only=<0|1> >>

See L<Conch::Route::Rack/POST /rack/:rack_id_or_name/phase?rack_only=01>.

=head2 C<POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/links>

See L<Conch::Route::Rack/POST /rack/:rack_id_or_name/links>.

=head2 C<DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/links>

See L<Conch::Route::Rack/DELETE /rack/:rack_id_or_name/links>.

=head2 C<GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start>

See L<Conch::Route::RackLayout/C<GET /layout/:layout_id>>.

=head2 C<POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start>

See L<Conch::Route::RackLayout/C<POST /layout/:layout_id>>.

=head2 C<DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start>

See L<Conch::Route::RackLayout/C<DELETE /layout/:layout_id>>.

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
