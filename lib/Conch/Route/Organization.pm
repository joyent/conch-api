package Conch::Route::Organization;

use Mojo::Base -strict, -signatures;

=pod

=head1 NAME

Conch::Route::Organization

=head1 METHODS

=head2 routes

Sets up the routes for /organization.

=cut

sub routes {
    my $class = shift;
    my $organization = shift; # secured, under /organization

    $organization->to({ controller => 'organization' });

    # GET /organization
    $organization->get('/')->to('#get_all');

    # POST /organization
    $organization->require_system_admin->post('/')->to('#create');

    {
        # chainable action that extracts and looks up organization_id from the path
        # and performs basic role checking for the organization
        my $with_organization = $organization->under('/:organization_id_or_name')
            ->to('#find_organization');

        # GET /organization/:organization_id_or_name
        $with_organization->get('/')->to('#get');

        # POST /organization/:organization_id_or_name
        $with_organization->post('/')->to('#update');

        # DELETE /organization/:organization_id_or_name
        $with_organization->require_system_admin->delete('/')->to('#delete');

        # POST /organization/:organization_id_or_name/user?send_mail=<1|0>
        $with_organization->find_user_from_payload->post('/user')->to('organization#add_user');

        # DELETE /organization/:organization_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>
        $with_organization->under('/user/#target_user_id_or_email')->to('user#find_user')
            ->delete('/')->to('organization#remove_user');
    }
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /organization>

=over 4

=item * Controller/Action: L<Conch::Controller::Organization/get_all>

=item * Response: F<response.yaml#/$defs/Organizations>

=back

=head2 C<POST /organization>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Organization/create>

=item * Request: F<request.yaml#/$defs/OrganizationCreate>

=item * Response: Redirect to the organization

=back

=head2 C<GET /organization/:organization_id_or_name>

=over 4

=item * Requires system admin authorization or the admin role on the organization

=item * Controller/Action: L<Conch::Controller::Organization/get>

=item * Response: F<response.yaml#/$defs/Organization>

=back

=head2 C<POST /organization/:organization_id_or_name>

=over 4

=item * Requires system admin authorization or the admin role on the organization

=item * Controller/Action: L<Conch::Controller::Organization/update>

=item * Request: F<request.yaml#/$defs/OrganizationUpdate>

=item * Response: Redirect to the organization

=back

=head2 C<DELETE /organization/:organization_id_or_name>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Organization/delete>

=item * Response: C<204 No Content>

=back

=head2 C<POST /organization/:organization_id_or_name/user?send_mail=<1|0>>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the user.

=over 4

=item * Requires system admin authorization or the admin role on the organization

=item * Controller/Action: L<Conch::Controller::Organization/add_user>

=item * Request: F<request.yaml#/$defs/OrganizationAddUser>

=item * Response: C<204 No Content>

=back

=head2 C<DELETE /organization/:organization_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the user.

=over 4

=item * Requires system admin authorization or the admin role on the organization

=item * Controller/Action: L<Conch::Controller::Organization/remove_user>

=item * Response: C<204 No Content>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
