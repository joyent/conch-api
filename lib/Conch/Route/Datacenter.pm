package Conch::Route::Datacenter;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Datacenter

=head1 METHODS

=head2 routes

Sets up the routes for /dc, /room, /rack_role, /rack and /layout:

=cut

sub routes {
    my $class = shift;
    my $r = shift;      # secured, under /

    # /dc
    {
        my $dc = $r->any('/dc');
        $dc->to({ controller => 'datacenter' });

        # GET /dc
        $dc->get('/')->to('#get_all');
        # POST /dc
        $dc->post('/')->to('#create');

        my $with_datacenter = $dc->under('/<datacenter_id:uuid>')->to('#find_datacenter');

        # GET /dc/:datacenter_id
        $with_datacenter->get('/')->to('#get_one');
        # POST /dc/:datacenter_id
        $with_datacenter->post('/')->to('#update');
        # DELETE /dc/:datacenter_id
        $with_datacenter->delete('/')->to('#delete');
        # GET /dc/:datacenter_id/rooms
        $with_datacenter->get('/rooms')->to('#get_rooms');
    }

    # /room
    {
        my $room = $r->any('/room');
        $room->to({ controller => 'datacenter_room' });

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

    # /rack_role
    {
        my $rack_role = $r->any('/rack_role');
        $rack_role->to({ controller => 'rack_role' });

        # GET /rack_role
        $rack_role->get('/')->to('#get_all');
        # POST /rack_role
        $rack_role->post('/')->to('#create');

        my $with_rack_role = $rack_role->under('/:rack_role_id_or_name')->to('#find_rack_role');

        # GET /rack_role/:rack_role_id_or_name
        $with_rack_role->get('/')->to('#get');
        # POST /rack_role/:rack_role_id_or_name
        $with_rack_role->post('/')->to('#update');
        # DELETE /rack_role/:rack_role_id_or_name
        $with_rack_role->delete('/')->to('#delete');
    }

    # /rack
    {
        my $rack = $r->any('/rack');
        $rack->to({ controller => 'rack' });

        # GET /rack
        $rack->get('/')->to('#get_all');
        # POST /rack
        $rack->post('/')->to('#create');

        my $with_rack = $rack->under('/<rack_id:uuid>')->to('#find_rack');

        # GET /rack/:rack_id
        $with_rack->get('/')->to('#get');
        # POST /rack/:rack_id
        $with_rack->post('/')->to('#update');
        # DELETE /rack/:rack_id
        $with_rack->delete('/')->to('#delete');
        # GET /rack/:rack_id/layouts
        $with_rack->get('/layouts')->to('#layouts');

        # GET /rack/:rack_id/assignment
        $with_rack->get('/assignment')->to('#get_assignment');
        # POST /rack/:rack_id/assignment
        $with_rack->post('/assignment')->to('#set_assignment');
        # DELETE /rack/:rack_id/assignment
        $with_rack->delete('/assignment')->to('#delete_assignment');

        # POST /rack/:rack_id/phase?rack_only=<0|1>
        $with_rack->post('/phase')->to('#set_phase');
    }

    # /layout
    {
        my $layout = $r->any('/layout');
        $layout->to({ controller => 'rack_layout' });

        # GET /layout
        $layout->get('/')->to('#get_all');
        # POST /layout
        $layout->post('/')->to('#create');

        my $with_layout = $layout->under('/<layout_id:uuid>')->to('#find_rack_layout');

        # GET /layout/:layout_id
        $with_layout->get('/')->to('#get');
        # POST /layout/:layout_id
        $with_layout->post('/')->to('#update');
        # DELETE /layout/:layout_id
        $with_layout->delete('/')->to('#delete');
    }
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=cut

=head3 C<GET /dc>

=over 4

=item * Response: response.yaml#/Datacenters

=back

=head3 C<POST /dc>

=over 4

=item * Request: input.yaml#/DatacenterCreate

=item * Response: Redirect to the created datacenter

=back

=head3 C<GET /dc/:datacenter_id>

=over 4

=item * Response: response.yaml#/Datacenter

=back

=head3 C<POST /dc/:datacenter_id>

=over 4

=item * Request: input.yaml#/DatacenterUpdate

=item * Response: Redirect to the updated datacenter

=back

=head3 C<DELETE /dc/:datacenter_id>

=over 4

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /dc/:datacenter_id/rooms>

=over 4

=item * Requires System Admin Authorization

=item * Response: response.yaml#/DatacenterRoomsDetailed

=back

=head3 C<GET /room>

=over 4

=item * Requires System Admin Authorization

=item * Response: response.yaml#/DatacenterRoomsDetailed

=back

=head3 C<POST /room>

=over 4

=item * Requires System Admin Authorization

=item * Request: input.yaml#/DatacenterRoomCreate

=item * Response: Redirect to the created room

=back

=head3 C<GET /room/:datacenter_room_id>


=over 4

=item * Requires System Admin Authorization

=item * Response: response.yaml#/DatacenterRoomDetailed

=back

=head3 C<POST /room/:datacenter_room_id>

=over 4

=item * Requires System Admin Authorization

=item * Request: input.yaml#/DatacenterRoomUpdate

=item * Response: Redirect to the updated room

=back

=head3 C<DELETE /room/:datacenter_room_id>

=over 4

=item * Requires System Admin Authorization

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /room/:datacenter_room_id/racks>

=over 4

=item * Requires System Admin Authorization

=item * Response: response.yaml#/Racks

=back

=head3 C<GET /rack_role>

=over 4

=item * Requires System Admin Authorization

=item * Response: response.yaml#/RackRoles

=back

=head3 C<POST /rack_role>

=over 4

=item * Requires System Admin Authorization

=item * Request: input.yaml#/RackRoleCreate

=item * Response: Redirect to the created rack role

=back

=head3 C<GET /rack_role/:rack_role_id_or_name>

=over 4

=item * Requires System Admin Authorization

=item * Response: response.yaml#/RackRole

=back

=head3 C<POST /rack_role/:rack_role_id_or_name>

=over 4

=item * Request: input.yaml#/RackRoleUpdate

=item * Response: Redirect to the updated rack role

=back

=head3 C<DELETE /rack_role/:rack_role_id_or_name>

=over 4

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /rack>

=over 4

=item * Requires System Admin Authentication

=item * Response: response.yaml#/Racks

=back

=head3 C<POST /rack>

=over 4

=item * Requires System Admin Authentication

=item * Request: input.yaml#/RackCreate

=item * Response: Redirect to the created rack

=back

=head3 C<GET /rack/:rack_id>

=over 4

=item * Response: response.yaml#/Rack

=back

=head3 C<POST /rack/:rack_id>

=over 4

=item * Request: input.yaml#/RackUpdate

=item * Response: Redirect to the updated rack

=back

=head3 C<DELETE /rack/:rack_id>

=over 4

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /rack/:rack_id/layouts>

=over 4

=item * Response: response.yaml#/RackLayouts

=back

=head3 C<GET /rack/:rack_id/assignment>

=over 4

=item * Response: response.yaml#/RackAssignments

=back

=head3 C<POST /rack/:rack_id/assignment>

=over 4

=item * Request: input.yaml#/RackAssignmentUpdates

=item * Response: Redirect to the updated rack assignment

=back

=head3 C<DELETE /rack/:rack_id/assignment>

This method requires a request body.

=over 4

=item * Request: input.yaml#/RackAssignmentDeletes

=item * Response: C<204 NO CONTENT>

=back

=head3 C<< POST /rack/:rack_id/phase?rack_only=<0|1> >>

The query parameter C<rack_only> (default 0) specifies whether to update
only the rack's phase, or all the rack's devices' phases as well.

=over 4

=item * Request: input.yaml#/RackPhase

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /layout>

=over 4

=item * Response: response.yaml#/RackLayouts

=back

=head3 C<POST /layout>

=over 4

=item * Requires Admin Authentication

=item * Request: input.yaml#/RackLayoutCreate

=item * Response: Redirect to the created rack layout

=back

=head3 C<GET /layout/:layout_id>

=over 4

=item * Response: response.yaml#/RackLayout

=back

=head3 C<POST /layout/:layout_id>

=over 4

=item * Request: input.yaml#/RackLayoutUpdate

=item * Response: Redirect to the update rack layout

=back

=head3 C<DELETE /layout/:layout_id>

=over 4

=item * Response: C<204 NO CONTENT>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
