package Conch::Route::Rack;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Rack

=head1 METHODS

=head2 routes

Sets up the routes for /rack:

=cut

sub routes {
    my $class = shift;
    my $rack = shift;   # secured, under /rack

    $rack->to({ controller => 'rack' });

    # GET /rack
    $rack->require_system_admin->get('/')->to('#get_all');
    # POST /rack
    $rack->require_system_admin->post('/')->to('#create');

    my $with_rack = $rack->under('/<rack_id:uuid>')->to('#find_rack');

    # GET /rack/:rack_id
    $with_rack->get('/')->to('#get');
    # POST /rack/:rack_id
    $with_rack->post('/')->to('#update');
    # DELETE /rack/:rack_id
    $with_rack->require_system_admin->delete('/')->to('#delete');

    # GET /rack/:rack_id/layouts
    $with_rack->get('/layouts')->to('#get_layouts');
    # POST /rack/:rack_id/layouts
    $with_rack->post('/layouts')->to('#overwrite_layouts');

    # GET /rack/:rack_id/assignment
    $with_rack->get('/assignment')->to('#get_assignment');
    # POST /rack/:rack_id/assignment
    $with_rack->post('/assignment')->to('#set_assignment');
    # DELETE /rack/:rack_id/assignment
    $with_rack->delete('/assignment')->to('#delete_assignment');

    # POST /rack/:rack_id/phase?rack_only=<0|1>
    $with_rack->post('/phase')->to('#set_phase');
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<GET /rack>

=over 4

=item * Requires system admin authorization

=item * Response: F<response.yaml#/definitions/Racks>

=back

=head3 C<POST /rack>

=over 4

=item * Requires system admin authorization

=item * Request: F<request.yaml#/definitions/RackCreate>

=item * Response: Redirect to the created rack

=back

=head3 C<GET /rack/:rack_id>

=over 4

=item * User requires the read-only role on a workspace that contains the rack

=item * Response: F<response.yaml#/definitions/Rack>

=back

=head3 C<POST /rack/:rack_id>

=over 4

=item * User requires the read/write role on a workspace that contains the rack

=item * Request: F<request.yaml#/definitions/RackUpdate>

=item * Response: Redirect to the updated rack

=back

=head3 C<DELETE /rack/:rack_id>

=over 4

=item * Requires system admin authorization

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /rack/:rack_id/layouts>

=over 4

=item * User requires the read-only role on a workspace that contains the rack

=item * Response: F<response.yaml#/definitions/RackLayouts>

=back

=head3 C<POST /rack/:rack_id/layouts>

=over 4

=item * User requires the read/write role on a workspace that contains the rack

=item * Request: F<request.yaml#/definitions/RackLayouts>

=item * Response: Redirect to the rack's layouts

=back

=head3 C<GET /rack/:rack_id/assignment>

=over 4

=item * User requires the read-only role on a workspace that contains the rack

=item * Response: F<response.yaml#/definitions/RackAssignments>

=back

=head3 C<POST /rack/:rack_id/assignment>

=over 4

=item * User requires the read/write role on a workspace that contains the rack

=item * Request: F<request.yaml#/definitions/RackAssignmentUpdates>

=item * Response: Redirect to the updated rack assignment

=back

=head3 C<DELETE /rack/:rack_id/assignment>

This method requires a request body.

=over 4

=item * User requires the read/write role on a workspace that contains the rack

=item * Request: F<request.yaml#/definitions/RackAssignmentDeletes>

=item * Response: C<204 NO CONTENT>

=back

=head3 C<< POST /rack/:rack_id/phase?rack_only=<0|1> >>

The query parameter C<rack_only> (defaults to C<0>) specifies whether to update
only the rack's phase, or all the rack's devices' phases as well.

=over 4

=item * User requires the read/write role on a workspace that contains the rack

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
