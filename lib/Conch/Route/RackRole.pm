package Conch::Route::RackRole;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::RackRole

=head1 METHODS

=head2 routes

Sets up the routes for /rack_role.

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

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /rack_role>

=over 4

=item * Controller/Action: L<Conch::Controller::RackRole/get_all>

=item * Response: F<response.yaml#/$defs/RackRoles>

=back

=head2 C<POST /rack_role>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::RackRole/create>

=item * Request: F<request.yaml#/$defs/RackRoleCreate>

=item * Response: Redirect to the created rack role

=back

=head2 C<GET /rack_role/:rack_role_id_or_name>

=over 4

=item * Controller/Action: L<Conch::Controller::RackRole/get>

=item * Response: F<response.yaml#/$defs/RackRole>

=back

=head2 C<POST /rack_role/:rack_role_id_or_name>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::RackRole/update>

=item * Request: F<request.yaml#/$defs/RackRoleUpdate>

=item * Response: Redirect to the updated rack role

=back

=head2 C<DELETE /rack_role/:rack_role_id_or_name>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::RackRole/delete>

=item * Response: C<204 No Content>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
