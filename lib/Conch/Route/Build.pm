package Conch::Route::Build;

use Mojo::Base -strict, -signatures;

=pod

=head1 NAME

Conch::Route::Build

=head1 METHODS

=head2 routes

Sets up the routes for /build.

=cut

sub routes {
    my $class = shift;
    my $build = shift; # secured, under /build

    $build->to({ controller => 'build' });

    # GET /build
    $build->get('/')->to('#list');

    # POST /build
    $build->require_system_admin->post('/')->to('#create');

    {
        # chainable actions that extract and looks up build_id from the path
        # and performs basic role checking for the build
        my $with_build_ro = $build->under('/:build_id_or_name')
            ->to('#find_build', require_role => 'ro');

        my $with_build_rw = $build->under('/:build_id_or_name')
            ->to('#find_build', require_role => 'rw');

        my $with_build_admin = $build->under('/:build_id_or_name')
            ->to('#find_build', require_role => 'admin');

        # GET /build/:build_id_or_name
        $with_build_ro->get('/')->to('#get');

        # POST /build/:build_id_or_name
        $with_build_admin->post('/')->to('#update');

        # GET /build/:build_id_or_name/user
        $with_build_admin->get('/user')->to('#list_users');

        # POST /build/:build_id_or_name/user?send_mail=<1|0>
        $with_build_admin->post('/user')->to('#add_user');

        # DELETE /build/:build_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>
        $with_build_admin
            ->under('/user/#target_user_id_or_email')->to('user#find_user')
            ->delete('/')->to('build#remove_user');

        {
            my $build_organization = $with_build_admin->any('/organization');

            # GET /build/:build_id_or_name/organization
            $build_organization->get('/')->to('#list_organizations');

            # POST /build/:build_id_or_name/organization?send_mail=<1|0>
            $build_organization->post('/')->to('#add_organization');

            # DELETE /build/:build_id_or_name/organization/:organization_id_or_name?send_mail=<1|0>
            $build_organization
                ->under('/:organization_id_or_name')->to('organization#find_organization')
                ->delete('/')->to('build#remove_organization');
        }

        # GET /build/:build_id_or_name/device
        $with_build_ro->get('/device')->to('#get_devices');

        # POST /build/:build_id_or_name/device
        $with_build_rw->post('/device')->to('#create_and_add_devices', require_role => 'rw');

        # POST /build/:build_id_or_name/device/:device_id_or_serial_number
        $with_build_rw->under('/device/:device_id_or_serial_number')
            ->to('device#find_device', require_role => 'rw')
            ->post('/')->to('build#add_device');

        # DELETE /build/:build_id_or_name/device/:device_id_or_serial_number
        $with_build_rw->under('/device/:device_id_or_serial_number')
            ->to('device#find_device', require_role => 'none')
            ->delete('/')->to('build#remove_device');

        # GET /build/:build_id_or_name/rack
        $with_build_ro->get('/rack')->to('#get_racks');

        # POST /build/:build_id_or_name/rack/:rack_id
        $with_build_rw->under('/rack/<rack_id:uuid>')
            ->to('rack#find_rack', require_role => 'rw')
            ->post('/')->to('build#add_rack');
    }
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<GET /build>

Takes one optional query parameter C<< device_health >> (defaults to false) to include
correlated counts of devices having each health value.

=over 4

=item * Response: response.yaml#/Builds

=back

=head3 C<POST /build>

=over 4

=item * Requires system admin authorization

=item * Request: request.yaml#/BuildCreate

=item * Response: Redirect to the build

=back

=head3 C<GET /build/:build_id_or_name>

Takes one optional query parameter C<< device_health >> (defaults to false) to include counts
of devices having each health value.

=over 4

=item * Requires system admin authorization or the read-only role on the build

=item * Response: response.yaml#/Build

=back

=head3 C<POST /build/:build_id_or_name>

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Request: request.yaml#/BuildUpdate

=item * Response: Redirect to the build

=back

=head3 C<GET /build/:build_id_or_name/user>

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Response: response.yaml#/BuildUsers

=back

=head3 C<POST /build/:build_id_or_name/user?send_mail=<1|0>>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the user.

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Request: request.yaml#/BuildAddUser

=item * Response: C<204 NO CONTENT>

=back

=head3 C<DELETE /build/:build_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the user.

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /build/:build_id_or_name/organization>

=over 4

=item * User requires the admin role

=item * Response: F<response.yaml#/definitions/BuildOrganizations>

=back

=head3 C<< POST /build/:build_id_or_name/organization?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the organization members and build admins.

=over 4

=item * User requires the admin role

=item * Request: F<request.yaml#/definitions/BuildAddOrganization>

=item * Response: C<204 NO CONTENT>

=back

=head3 C<< DELETE /build/:build_id_or_name/organization/:organization_id_or_name?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the organization members and build admins.

=over 4

=item * User requires the admin role

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /build/:build_id_or_name/device>

Accepts the following optional query parameters:

=over 4

=item * C<< health=<value> >> show only devices with the health matching the provided value
(can be used more than once)

=item * C<active_minutes=X> show only devices which have reported within the last X minutes

=item * C<ids_only=1> only return device IDs, not full device details

=back

=over 4

=item * Requires system admin authorization or the read-only role on the build

=item * Response: F<response.yaml#/definitions/Devices>, F<response.yaml#/definitions/DeviceIds> or F<response.yaml#/definitions/DeviceSerials>

=back

=head3 C<POST /build/:build_id_or_name/device>

=over 4

=item * Requires system admin authorization, or the read/write role on the build and the
read-write role on existing device(s) (via a workspace or build; see
L<Conch::Route::Device/routes>)

=item * Request: F<request.yaml#/definitions/BuildCreateDevices>

=item * Response: C<204 NO CONTENT>

=back

=head3 C<POST /build/:build_id_or_name/device/:device_id_or_serial_number>

=over 4

=item * Requires system admin authorization, or the read/write role on the build and the
read-write role on the device (via a workspace or build; see L<Conch::Route::Device/routes>)

=item * Response: C<204 NO CONTENT>

=back

=head3 C<DELETE /build/:build_id_or_name/device/:device_id_or_serial_number>

=over 4

=item * Requires system admin authorization, or the read/write role on the build

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /build/:build_id_or_name/rack>

=over 4

=item * Requires system admin authorization or the read-only role on the build

=item * Response: response.yaml#/Racks

=back

=head3 C<POST /build/:build_id_or_name/rack/:rack_id>

=over 4

=item * Requires system admin authorization, or the read/write role on the build and the
read-write role on a workspace or build that contains the rack

=item * Response: C<204 NO CONTENT>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
