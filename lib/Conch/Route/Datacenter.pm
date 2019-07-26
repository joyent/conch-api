package Conch::Route::Datacenter;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Datacenter

=head1 METHODS

=head2 routes

Sets up the routes for /dc:

=cut

sub routes {
    my $class = shift;
    my $dc = shift;     # secured, under /dc

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

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<GET /dc>

=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/Datacenters

=back

=head3 C<POST /dc>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/DatacenterCreate

=item * Response: C<201 CREATED> or C<204 NO CONTENT>, plus Location header

=back

=head3 C<GET /dc/:datacenter_id>

=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/Datacenter

=back

=head3 C<POST /dc/:datacenter_id>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/DatacenterUpdate

=item * Response: Redirect to the updated datacenter

=back

=head3 C<DELETE /dc/:datacenter_id>

=over 4

=item * Requires system admin authorization

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /dc/:datacenter_id/rooms>

=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/DatacenterRoomsDetailed

=back

=head3 C<GET /room>

=over 4

=item * Requires system admin authorization

=item * Response: response.yaml#/DatacenterRoomsDetailed

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
