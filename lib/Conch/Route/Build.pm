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
    $build->get('/')->to('#get_all', query_params_schema => 'GetBuilds', response_schema => 'Builds');

    # POST /build
    $build->require_system_admin->post('/')->to('#create', request_schema => 'BuildCreate');

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
        $with_build_ro->get('/')->to('#get', query_params_schema => 'GetBuild', response_schema => 'Build');

        # POST /build/:build_id_or_name
        $with_build_admin->post('/')->to('#update', request_schema => 'BuildUpdate');

        # POST /build/:build_id_or_name/links
        $with_build_admin->post('/links')->to('#add_links', request_schema => 'BuildLinks');

        # DELETE /build/:build_id_or_name/links
        $with_build_admin->delete('/links')->to('#remove_links', request_schema => 'BuildLinksOrNull');

        # GET /build/:build_id_or_name/user
        $with_build_admin->get('/user')->to('#get_users', response_schema => 'BuildUsers');

        # POST /build/:build_id_or_name/user?send_mail=<1|0>
        $with_build_admin->find_user_from_payload->post('/user')
            ->to('build#add_user', query_params_schema => 'NotifyUsers',
                request_schema => 'BuildAddUser');

        # DELETE /build/:build_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>
        $with_build_admin
            ->under('/user/#target_user_id_or_email')->to('user#find_user')
            ->delete('/')->to('build#remove_user', query_params_schema => 'NotifyUsers');

        {
            my $build_organization = $with_build_admin->any('/organization');

            # GET /build/:build_id_or_name/organization
            $build_organization->get('/')->to('#get_organizations', response_schema => 'BuildOrganizations');

            # POST /build/:build_id_or_name/organization?send_mail=<1|0>
            $build_organization->post('/')
                ->to('#add_organization', query_params_schema => 'NotifyUsers',
                    request_schema => 'BuildAddOrganization');

            # DELETE /build/:build_id_or_name/organization/:organization_id_or_name?send_mail=<1|0>
            $build_organization
                ->under('/:organization_id_or_name')->to('organization#find_organization')
                ->delete('/')->to('build#remove_organization', query_params_schema => 'NotifyUsers');
        }

        my $build_devices = $with_build_ro->under('/device')
            ->to('#find_devices', query_params_schema => 'FindDevice');

        # GET /build/:build_id_or_name/device
        $build_devices->get('/')
            ->to('#get_devices', query_params_schema => 'BuildDevices',
                response_schema => [ qw(Devices DeviceIds DeviceSerials) ]);

        # GET /build/:build_id_or_name/device/pxe
        $build_devices->get('/pxe')->to('#get_pxe_devices', response_schema => 'DevicePXEs');

        # POST /build/:build_id_or_name/device
        $with_build_rw->post('/device')->to('#create_and_add_devices', require_role => 'rw',
            request_schema => 'BuildCreateDevices');

        # POST /build/:build_id_or_name/device/:device_id_or_serial_number
        $with_build_rw->under('/device/:device_id_or_serial_number')
            ->to('device#find_device', require_role => 'rw')
            ->post('/')->to('build#add_device', request_schema => 'Null');

        # DELETE /build/:build_id_or_name/device/:device_id_or_serial_number
        $with_build_rw->under('/device/:device_id_or_serial_number')
            ->to('device#find_device', require_role => 'none')
            ->delete('/')->to('build#remove_device');

        # GET /build/:build_id_or_name/rack
        $with_build_ro->get('/rack')->to('#get_racks',
            query_params_schema => 'BuildRacks', response_schema => [ qw(Racks RackIds) ]);

        # POST /build/:build_id_or_name/rack/:rack_id_or_name
        $with_build_rw->under('/rack/:rack_id_or_name')
            ->to('rack#find_rack', require_role => 'rw')
            ->post('/')->to('build#add_rack', request_schema => 'Null');
    }
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /build>

Supports the following optional query parameters:

=over 4

=item * C<< started=<0|1> >> only return unstarted, or started, builds respectively

=item * C<< completed=<0|1> >> only return incomplete, or complete, builds respectively

=back

=over 4

=item * Controller/Action: L<Conch::Controller::Build/get_all>

=item * Response: F<response.yaml#/$defs/Builds>

=back

=head2 C<POST /build>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::Build/create>

=item * Request: F<request.yaml#/$defs/BuildCreate>

=item * Response: C<201 Created>, plus Location header

=back

=head2 C<GET /build/:build_id_or_name>

Supports the following optional query parameters:

=over 4

=item * C<with_device_health> - includes correlated counts of devices having each health value

=item * C<with_device_phases> - includes correlated counts of devices having each phase value

=item * C<with_rack_phases> - includes correlated counts of racks having each phase value

=back

=over 4

=item * Controller/Action: L<Conch::Controller::Build/get>

=item * Requires system admin authorization or the read-only role on the build

=item * Response: F<response.yaml#/$defs/Build>

=back

=head2 C<POST /build/:build_id_or_name>

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Controller/Action: L<Conch::Controller::Build/update>

=item * Request: F<request.yaml#/$defs/BuildUpdate>

=item * Response: C<204 No Content>, plus Location header

=back

=head3 C<POST /build/:build_id_or_name/links>

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Controller/Action: L<Conch::Controller::Build/add_links>

=item * Request: F<request.yaml#/$defs/BuildLinks>

=item * Response: C<204 No Content>, plus Location header

=back

=head3 C<DELETE /build/:build_id_or_name/links>

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Request: F<request.yaml#/$defs/BuildLinksOrNull>

=item * Response: 204 NO CONTENT

=back

=head2 C<GET /build/:build_id_or_name/user>

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Controller/Action: L<Conch::Controller::Build/get_users>

=item * Response: F<response.yaml#/$defs/BuildUsers>

=back

=head2 C<POST /build/:build_id_or_name/user?send_mail=<1|0>>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the user.

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Controller/Action: L<Conch::Controller::Build/add_user>

=item * Request: F<request.yaml#/$defs/BuildAddUser>

=item * Response: C<204 No Content>

=back

=head2 C<DELETE /build/:build_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the user.

=over 4

=item * Requires system admin authorization or the admin role on the build

=item * Controller/Action: L<Conch::Controller::Build/remove_user>

=item * Response: C<204 No Content>

=back

=head2 C<GET /build/:build_id_or_name/organization>

=over 4

=item * User requires the admin role

=item * Controller/Action: L<Conch::Controller::Build/get_organizations>

=item * Response: F<response.yaml#/$defs/BuildOrganizations>

=back

=head2 C<< POST /build/:build_id_or_name/organization?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the organization members and build admins.

=over 4

=item * User requires the admin role

=item * Controller/Action: L<Conch::Controller::Build/add_organization>

=item * Request: F<request.yaml#/$defs/BuildAddOrganization>

=item * Response: C<204 No Content>

=back

=head2 C<< DELETE /build/:build_id_or_name/organization/:organization_id_or_name?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the organization members and build admins.

=over 4

=item * User requires the admin role

=item * Controller/Action: L<Conch::Controller::Build/remove_organization>

=item * Response: C<204 No Content>

=back

=head2 C<GET /build/:build_id_or_name/device>

Accepts the following optional query parameters:

=over 4

=item * C<health=:value> show only devices with the health matching the provided value
(can be used more than once)

=item * C<phase=:value> show only devices with the phase matching the provided value
(can be used more than once)

=item * C<active_minutes=:X> show only devices which have reported within the last X minutes

=item * C<ids_only=1> only return device IDs, not full device details

=back

=over 4

=item * Requires system admin authorization or the read-only role on the build

=item * Controller/Action: L<Conch::Controller::Build/get_devices>

=item * Response: one of F<response.yaml#/$defs/Devices>, F<response.yaml#/$defs/DeviceIds> or F<response.yaml#/$defs/DeviceSerials>

=back

=head2 C<GET /build/:build_id_or_name/device/pxe>

=over 4

=item * Requires system admin authorization or the read-only role on the build

=item * Controller/Action: L<Conch::Controller::Build/get_pxe_devices>

=item * Response: F<response.yaml#/$defs/DevicePXEs>

=back

=head2 C<POST /build/:build_id_or_name/device>

=over 4

=item * Requires system admin authorization, or the read/write role on the build and the
read-only role on the device (via a build or a relay registration, see
L<Conch::Route::Device/routes>)

=item * Controller/Action: L<Conch::Controller::Build/create_and_add_devices>

=item * Request: F<request.yaml#/$defs/BuildCreateDevices>

=item * Response: C<204 No Content>

=back

=head2 C<POST /build/:build_id_or_name/device/:device_id_or_serial_number>

=over 4

=item * Requires system admin authorization, or the read/write role on the build and the
read-write role on the device (via a build; see L<Conch::Route::Device/routes>)

=item * Controller/Action: L<Conch::Controller::Build/add_device>

=item * Request: F<request.yaml#/$defs/Null>

=item * Response: C<204 No Content>

=back

=head2 C<DELETE /build/:build_id_or_name/device/:device_id_or_serial_number>

=over 4

=item * Requires system admin authorization, or the read/write role on the build

=item * Controller/Action: L<Conch::Controller::Build/remove_device>

=item * Response: C<204 No Content>

=back

=head2 C<GET /build/:build_id_or_name/rack>

Accepts the following optional query parameters:

=over 4

=item * C<phase=:value> show only racks with the phase matching the provided value
(can be used more than once)

=item * C<ids_only=1> only return rack IDs, not full rack details

=back

=over 4

=item * Requires system admin authorization, or the read/write role on the build and the
read-only role on a build that contains the rack

=item * Controller/Action: L<Conch::Controller::Build/get_racks>

=item * Response: one of F<response.yaml#/$defs/Racks> or F<response.yaml#/$defs/RackIds>

=back

=head2 C<POST /build/:build_id_or_name/rack/:rack_id_or_name>

=over 4

=item * Requires system admin authorization, or the read/write role on the build and the
read-write role on a build that contains the rack

=item * Controller/Action: L<Conch::Controller::Build/add_rack>

=item * Request: F<request.yaml#/$defs/Null>

=item * Response: C<204 No Content>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
