package Conch::Route::RackLayout;

use Mojo::Base -strict, -signatures;

=pod

=head1 NAME

Conch::Route::RackLayout

=head1 METHODS

=head2 routes

Sets up the routes for /layout.

=cut

sub routes {
    my $class = shift;
    my $layout = shift; # secured, under /layout

    $layout = $layout->require_system_admin->to({ controller => 'rack_layout' });

    # GET /layout
    $layout->get('/')->to('#get_all', response_schema => 'RackLayouts');
    # POST /layout
    $layout->post('/')->to('#create', request_schema => 'RackLayoutCreate');

    # GET /layout/:layout_id
    # POST /layout/:layout_id
    # DELETE /layout/:layout_id
    $class->one_layout_routes($layout);
}

=head2 one_layout_routes

Sets up the routes for working with just one layout, mounted under a provided route prefix.

=cut

sub one_layout_routes ($class, $r) {
    my $with_layout = $r->under('/:layout_id_or_rack_unit_start')->to('#find_rack_layout', controller => 'rack_layout');

    # GET .../layout/:layout_id_or_rack_unit_start
    $with_layout->get('/')->to('#get', response_schema => 'RackLayout');
    # POST .../layout/:layout_id_or_rack_unit_start
    $with_layout->post('/')->to('#update', request_schema => 'RackLayoutUpdate');
    # DELETE .../layout/:layout_id_or_rack_unit_start
    $with_layout->delete('/')->to('#delete');
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

Take note: All routes that reference a specific rack layout (prefix C</layout/:layout_id>) are
also available under C</rack/:rack_id_or_long_name/layout/:layout_id_or_rack_unit_start> as
well as
C</room/datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start>.

=head2 C<GET /layout>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::RackLayout/get_all>

=item * Response: F<response.yaml#/$defs/RackLayouts>

=back

=head2 C<POST /layout>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::RackLayout/create>

=item * Request: F<request.yaml#/$defs/RackLayoutCreate>

=item * Response: Redirect to the created rack layout

=back

=head2 C<GET /layout/:layout_id>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::RackLayout/get>

=item * Response: F<response.yaml#/$defs/RackLayout>

=back

=head2 C<POST /layout/:layout_id>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::RackLayout/update>

=item * Request: F<request.yaml#/$defs/RackLayoutUpdate>

=item * Response: Redirect to the update rack layout

=back

=head2 C<DELETE /layout/:layout_id>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::RackLayout/delete>

=item * Response: C<204 No Content>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
