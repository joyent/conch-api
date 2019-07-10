package Conch::Route::RackLayout;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::RackLayout

=head1 METHODS

=head2 routes

Sets up the routes for /layout:

=cut

sub routes {
    my $class = shift;
    my $layout = shift; # secured, under /layout

    $layout = $layout->require_system_admin->to({ controller => 'rack_layout' });

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

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<GET /layout>

=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/RackLayouts

=back

=head3 C<POST /layout>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/RackLayoutCreate

=item * Response: Redirect to the created rack layout

=back

=head3 C<GET /layout/:layout_id>

=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/RackLayout

=back

=head3 C<POST /layout/:layout_id>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/RackLayoutUpdate

=item * Response: Redirect to the update rack layout

=back

=head3 C<DELETE /layout/:layout_id>

=over 4

=item * Requires system admin authorization

=item * Response: C<204 NO CONTENT>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
