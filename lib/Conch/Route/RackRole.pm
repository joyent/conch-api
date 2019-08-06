package Conch::Route::RackRole;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::RackRole

=head1 METHODS

=head2 routes

Sets up the routes for /rack_role:

=cut

sub routes {
    my $class = shift;
    my $rack_role = shift;  # secured, under /rack_role

    $rack_role->to({ controller => 'rack_role' });

    # GET /rack_role
    $rack_role->get('/')->to('#get_all');
    # POST /rack_role
    $rack_role->require_system_admin->post('/')->to('#create');

    my $with_rack_role = $rack_role->under('/:rack_role_id_or_name')->to('#find_rack_role');

    # GET /rack_role/:rack_role_id_or_name
    $with_rack_role->get('/')->to('#get');
    # POST /rack_role/:rack_role_id_or_name
    $with_rack_role->require_system_admin->post('/')->to('#update');
    # DELETE /rack_role/:rack_role_id_or_name
    $with_rack_role->require_system_admin->delete('/')->to('#delete');
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<GET /rack_role>

=over 4

=item * Response: response.yaml#/RackRoles

=back

=head3 C<POST /rack_role>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/RackRoleCreate

=item * Response: Redirect to the created rack role

=back

=head3 C<GET /rack_role/:rack_role_id_or_name>

=over 4

=item * Response: response.yaml#/RackRole

=back

=head3 C<POST /rack_role/:rack_role_id_or_name>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/RackRoleUpdate

=item * Response: Redirect to the updated rack role

=back

=head3 C<DELETE /rack_role/:rack_role_id_or_name>

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
