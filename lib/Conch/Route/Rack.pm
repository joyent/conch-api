package Conch::Route::Rack;

use Mojo::Base -strict, -signatures;

=pod

=head1 NAME

Conch::Route::Rack

=head1 METHODS

=head2 routes

Sets up the routes for /rack.

=cut

sub routes {
    my $class = shift;
    my $rack = shift;   # secured, under /rack

    $rack->to({ controller => 'rack' });

    my $rack_with_system_admin = $rack->require_system_admin;

    # POST /rack
    $rack_with_system_admin->post('/')->to('#create', request_schema => 'RackCreate');

    # for these endpoints, rack name must be a long name (room_vendor_name:rack_name) --
    # short name is only supported when room qualifier is included (see /room/* endpoints)

    # GET    /rack/:rack_id_or_name
    # POST   /rack/:rack_id_or_name
    # DELETE /rack/:rack_id_or_name
    # GET    /rack/:rack_id_or_name/layout
    # POST   /rack/:rack_id_or_name/layout
    # GET    /rack/:rack_id_or_name/assignment
    # POST   /rack/:rack_id_or_name/assignment
    # DELETE /rack/:rack_id_or_name/assignment
    # POST   /rack/:rack_id_or_name/phase?rack_only=<0|1>
    # POST   /rack/:rack_id_or_name/links
    # DELETE /rack/:rack_id_or_name/links
    # GET    /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
    # POST   /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
    # DELETE /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
    $class->one_rack_routes($rack);
}

=head2 one_rack_routes

Sets up the routes for working with just one rack, mounted under a provided route prefix.

=cut

sub one_rack_routes ($class, $r) {
    my $one_rack = $r->under('/#rack_id_or_name')->to('#find_rack', controller => 'rack');

    # GET .../rack/:rack_id_or_name
    $one_rack->get('/')->to('#get', response_schema => 'Rack');
    # POST .../rack/:rack_id_or_name
    $one_rack->post('/')->to('#update', request_schema => 'RackUpdate');
    # DELETE .../rack/:rack_id_or_name
    $one_rack->require_system_admin->delete('/')->to('#delete');

    # GET .../rack/:rack_id_or_name/layout
    $one_rack->get('/layouts', sub { shift->status(308, 'get_layouts') });
    $one_rack->get('/layout', 'get_layouts')->to('#get_layouts', response_schema => 'RackLayouts');

    # POST .../rack/:rack_id_or_name/layout
    $one_rack->post('/layouts', { request_schema => 'Anything' },
        sub { shift->status(308, 'overwrite_layouts') });
    $one_rack->post('/layout', 'overwrite_layouts')
        ->to('#overwrite_layouts', request_schema => 'RackLayouts');

    # GET .../rack/:rack_id_or_name/assignment
    $one_rack->get('/assignment')->to('#get_assignment', response_schema => 'RackAssignments');
    # POST .../rack/:rack_id_or_name/assignment
    $one_rack->post('/assignment')->to('#set_assignment', request_schema => 'RackAssignmentUpdates');
    # DELETE .../rack/:rack_id_or_name/assignment
    $one_rack->delete('/assignment')->to('#delete_assignment', request_schema => 'RackAssignmentDeletes');

    # POST .../rack/:rack_id_or_name/phase?rack_only=<0|1>
    $one_rack->post('/phase')->to('#set_phase', query_params_schema => 'SetPhase', request_schema => 'RackPhase');

    # POST .../rack/:rack_id_or_name/links
    $one_rack->post('/links')->to('#add_links', request_schema => 'RackLinks');

    # DELETE .../rack/:rack_id_or_name/links
    $one_rack->delete('/links')->to('#remove_links', request_schema => 'RackLinksOrNull');

    # GET .../rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
    # POST .../rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
    # DELETE .../rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start
    Conch::Route::RackLayout->one_layout_routes($one_rack->any('/layout'));
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

Take note: All routes that reference a specific rack (prefix C</rack/:rack_id>) are also
available under C</rack/:rack_id_or_long_name> as well as
C</room/datacenter_room_id_or_alias/rack/:rack_id_or_name>.

=head2 C<POST /rack>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Rack/create>

=item * Request: F<request.yaml#/$defs/RackCreate>

=item * Response: C<201 Created>, plus Location header

=back

=head2 C<GET /rack/:rack_id_or_name>

=over 4

=item * User requires the read-only role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/get>

=item * Response: F<response.yaml#/$defs/Rack>

=back

=head2 C<POST /rack/:rack_id_or_name>

=over 4

=item * User requires the read/write role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/update>

=item * Request: F<request.yaml#/$defs/RackUpdate>

=item * Response: C<204 No Content>, plus Location header

=back

=head2 C<DELETE /rack/:rack_id_or_name>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Rack/delete>

=item * Response: C<204 No Content>

=back

=head2 C<GET /rack/:rack_id_or_name/layout>

=over 4

=item * User requires the read-only role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/get_layouts>

=item * Response: F<response.yaml#/$defs/RackLayouts>

=back

=head2 C<POST /rack/:rack_id_or_name/layout>

=over 4

=item * User requires the read/write role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/overwrite_layouts>

=item * Request: F<request.yaml#/$defs/RackLayouts>

=item * Response: C<204 No Content>, plus Location header

=back

=head2 C<GET /rack/:rack_id_or_name/assignment>

=over 4

=item * User requires the read-only role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/get_assignment>

=item * Response: F<response.yaml#/$defs/RackAssignments>

=back

=head2 C<POST /rack/:rack_id_or_name/assignment>

=over 4

=item * User requires the read/write role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/set_assignment>

=item * Request: F<request.yaml#/$defs/RackAssignmentUpdates>

=item * Response: C<204 No Content>, plus Location header

=back

=head2 C<DELETE /rack/:rack_id_or_name/assignment>

This method requires a request body.

=over 4

=item * User requires the read/write role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/delete_assignment>

=item * Request: F<request.yaml#/$defs/RackAssignmentDeletes>

=item * Response: C<204 No Content>

=back

=head2 C<< POST /rack/:rack_id_or_name/phase?rack_only=<0|1> >>

The query parameter C<rack_only> (defaults to C<0>) specifies whether to update
only the rack's phase, or all the rack's devices' phases as well.

=over 4

=item * User requires the read/write role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/set_phase>

=item * Request: F<request.yaml#/$defs/RackPhase>

=item * Response: C<204 No Content>, plus Location header

=back

=head3 C<POST /rack/:rack_id_or_name/links>

=over 4

=item * User requires the read/write role on the rack

=item * Controller/Action: L<Conch::Controller::Rack/add_links>

=item * Request: F<request.yaml#/$defs/RackLinks>

=item * Response: C<204 No Content>, plus Location header

=back

=head3 C<DELETE /rack/:rack_id_or_name/links>

=over 4

=item * User requires the read/write role on the rack

=item * Request: F<request.yaml#/$defs/RackLinksOrNull>

=item * Response: C<204 No Content>, plus Location header

=back

=head2 C<GET /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start>

See L<Conch::Route::RackLayout/C<GET /layout/:layout_id>>.

=head2 C<POST /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start>

See L<Conch::Route::RackLayout/C<POST /layout/:layout_id>>.

=head2 C<DELETE /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start>

See L<Conch::Route::RackLayout/C<DELETE /layout/:layout_id>>.

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
