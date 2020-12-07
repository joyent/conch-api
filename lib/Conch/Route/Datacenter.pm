package Conch::Route::Datacenter;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Datacenter

=head1 METHODS

=head2 routes

Sets up the routes for /dc.

=cut

sub routes {
    my $class = shift;
    my $dc = shift;     # secured, under /dc

    $dc = $dc->require_system_admin->to({ controller => 'datacenter' });

    # GET /dc
    $dc->get('/')->to('#get_all', response_schema => 'Datacenters');
    # POST /dc
    $dc->post('/')->to('#create', request_schema => 'DatacenterCreate');

    my $with_datacenter = $dc->under('/<datacenter_id:uuid>')->to('#find_datacenter');

    # GET /dc/:datacenter_id
    $with_datacenter->get('/')->to('#get_one', response_schema => 'Datacenter');
    # POST /dc/:datacenter_id
    $with_datacenter->post('/')->to('#update', request_schema => 'DatacenterUpdate');
    # DELETE /dc/:datacenter_id
    $with_datacenter->delete('/')->to('#delete');
    # GET /dc/:datacenter_id/rooms
    $with_datacenter->get('/rooms')->to('#get_rooms', response_schema => 'DatacenterRoomsDetailed');
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /dc>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Datacenter/get_all>

=item * Response: F<response.yaml#/$defs/Datacenters>

=back

=head2 C<POST /dc>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Datacenter/create>

=item * Request: F<request.yaml#/$defs/DatacenterCreate>

=item * Response: C<201 Created> or C<204 No Content>, plus Location header

=back

=head2 C<GET /dc/:datacenter_id>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Datacenter/get_one>

=item * Response: F<response.yaml#/$defs/Datacenter>

=back

=head2 C<POST /dc/:datacenter_id>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Datacenter/update>

=item * Request: F<request.yaml#/$defs/DatacenterUpdate>

=item * Response: C<204 No Content>, plus Location header

=back

=head2 C<DELETE /dc/:datacenter_id>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Datacenter/delete>

=item * Response: C<204 No Content>

=back

=head2 C<GET /dc/:datacenter_id/rooms>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Datacenter/get_rooms>

=item * Response: F<response.yaml#/$defs/DatacenterRoomsDetailed>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
