package Conch::Route::Device;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Device

=head1 METHODS

=head2 routes

Sets up the routes for /device:

=cut

sub routes {
    my $class = shift;
    my $device = shift; # secured, under /device
    my $app = shift;

    # TODO: this should be POST /device_report
    # POST /device/:device_serial_number
    $device->post('/:device_serial_number')->to('device_report#process');

    # GET /device?:key=:value
    $device->get('/')->to('device#lookup_by_other_attribute');

    {
        # chainable actions that extract and look up the device id or serial_number from the path
        my $with_device = $device->under('/:device_id_or_serial_number')->to('device#find_device');
        my $with_device_ro = $device->under('/:device_id_or_serial_number')
            ->to('device#find_device', require_role => 'ro');
        my $with_device_phase_earlier_than_prod = $device->under('/:device_id_or_serial_number')
            ->to('device#find_device', phase_earlier_than => 'production');

        # GET /device/:device_id_or_serial_number
        $with_device->get('/')->to('device#get');

        # GET /device/:device_id_or_serial_number/pxe
        $with_device_phase_earlier_than_prod->get('/pxe')->to('device#get_pxe');
        # GET /device/:device_id_or_serial_number/phase
        $with_device->get('/phase')->to('device#get_phase');
        # GET /device/:device_id_or_serial_number/sku
        $with_device->get('/sku')->to('device#get_sku');

        # POST /device/:device_id_or_serial_number/asset_tag
        $with_device->post('/asset_tag')->to('device#set_asset_tag');
        # POST /device/:device_id_or_serial_number/validated
        $with_device->post('/validated')->to('device#set_validated');
        # POST /device/:device_id_or_serial_number/phase
        $with_device->post('/phase')->to('device#set_phase');
        # POST /device/:device_id_or_serial_number/links
        $with_device->post('/links')->to('device#add_links');
        # DELETE /device/:device_id_or_serial_number/links
        $with_device->delete('/links')->to('device#remove_links');

        {
            my $with_device_location = $with_device_phase_earlier_than_prod->any('/location')
                ->to({ controller => 'device_location' });

            # GET /device/:device_id_or_serial_number/location
            $with_device_location->get('/')->to('#get');
            # POST /device/:device_id_or_serial_number/location
            $with_device_location->post('/')->to('#set');
            # DELETE /device/:device_id_or_serial_number/location
            $with_device_location->delete('/')->to('#delete');
        }

        {
            my $with_device_settings = $with_device->any('/settings')
                ->to({ controller => 'device_settings' });

            # GET /device/:device_id_or_serial_number/settings
            $with_device_settings->get('/')->to('#get_all');
            # POST /device/:device_id_or_serial_number/settings
            $with_device_settings->post('/')->to('#set_all');

            my $with_device_settings_with_key = $with_device_settings->any('/#key');
            # GET /device/:device_id_or_serial_number/settings/#key
            $with_device_settings_with_key->get('/')->to('#get_single');
            # POST /device/:device_id_or_serial_number/settings/#key
            $with_device_settings_with_key->post('/')->to('#set_single');
            # DELETE /device/:device_id_or_serial_number/settings/#key
            $with_device_settings_with_key->delete('/')->to('#delete_single');
        }

        # POST /device/:device_id_or_serial_number/validation/:validation_id
        $with_device_ro->post('/validation/<validation_id:uuid>')->to('device_validation#validate');
        # POST /device/:device_id_or_serial_number/validation_plan/:validation_plan_id
        $with_device_ro->post('/validation_plan/<validation_plan_id:uuid>')->to('device_validation#run_validation_plan');
        # GET /device/:device_id_or_serial_number/validation_state?status=<pass|fail|error>&status=...
        $with_device->get('/validation_state')->to('device_validation#list_validation_states');

        {
            my $with_device_interface = $with_device_phase_earlier_than_prod
                ->any('/interface')->to({ controller => 'device_interface' });

            # GET /device/:device_id_or_serial_number/interface
            $with_device_interface->get('/')->to('#get_all');

            # chainable action that extracts and looks up interface_name from the path
            my $with_interface_name = $with_device_interface->under('/#interface_name')->to('#find_device_interface');

            # GET /device/:device_id_or_serial_number/interface/#interface_name
            $with_interface_name->get('/')->to('#get_one');

            # GET /device/:device_id_or_serial_number/interface/#interface_name/:field
            $with_interface_name->get('/:field', [ field => [ $app->db_device_nics->fields ] ])
                ->to('#get_one_field');
        }
    }
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

The user's role (required for most endpoints) is determined by the rack location of the device,
and the workspace(s) the rack is contained in (where users are assigned a
L<role|Conch::DB::Result::UserWorkspaceRole/role> in that workspace).

Full (admin-level) access is also granted to a device if a report was sent for that device
using a relay that registered with that user's credentials.

=head3 C<POST /device/:device_serial_number>

=over 4

=item * Request: F<device_report.yaml#/definitions/DeviceReport>

=item * Response: F<response.yaml#/definitions/ValidationStateWithResults>

=back

=head3 C<GET /device?:key=:value>

Supports the following query parameters:

=over 4

=item * C</device?hostname=:hostname>

=item * C</device?mac=:macaddr>

=item * C</device?ipaddr=:ipaddr>

=item * C</device?:setting_key=:setting_value>

=back

The value of C<:setting_key> and C<:setting_value> are a device setting key and
value. For information on how to create a setting key or set its value see
below.

=over 4

=item * Response: F<response.yaml#/definitions/Devices>

=back

=head3 C<GET /device/:device_id_or_serial_number>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DetailedDevice>

=back

=head3 C<GET /device/:device_id_or_serial_number/pxe>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DevicePXE>

=back

=head3 C<GET /device/:device_id_or_serial_number/phase>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DevicePhase>

=back

=head3 C<GET /device/:device_id_or_serial_number/sku>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DeviceSku>

=back

=head3 C<POST /device/:device_id_or_serial_number/asset_tag>

=over 4

=item * User requires the read/write role

=item * Request: F<request.yaml#/definitions/DeviceAssetTag>

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id_or_serial_number/validated>

=over 4

=item * User requires the read/write role

=item * Request: F<request.yaml#/definitions/Null>

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id_or_serial_number/phase>

=over 4

=item * User requires the read/write role

=item * Request: F<request.yaml#/definitions/DevicePhase>

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id_or_serial_number/links>

=over 4

=item * User requires the read/write role

=item * Request: F<request.yaml#/definitions/DeviceLinks>

=item * Response: Redirect to the updated device

=back

=head3 C<DELETE /device/:device_id_or_serial_number/links>

=over 4

=item * User requires the read/write role

=item * Response: 204 NO CONTENT

=back

=head3 C<GET /device/:device_id_or_serial_number/location>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DeviceLocation>

=back

=head3 C<POST /device/:device_id_or_serial_number/location>

=over 4

=item * User requires the read/write role

=item * Request: F<request.yaml#/definitions/DeviceLocationUpdate>

=item * Response: Redirect to the updated device

=back

=head3 C<DELETE /device/:device_id_or_serial_number/location>

=over 4

=item * User requires the read/write role

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /device/:device_id_or_serial_number/settings>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DeviceSettings>

=back

=head3 C<POST /device/:device_id_or_serial_number/settings>

=over 4

=item * User requires the read/write role, or admin when overwriting existing
settings that do not start with C<tag.>.

=item * Request: F<request.yaml#/definitions/DeviceSettings>

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /device/:device_id_or_serial_number/settings/:key>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DeviceSetting>

=back

=head3 C<POST /device/:device_id_or_serial_number/settings/:key>

=over 4

=item * User requires the read/write role, or admin when overwriting existing
settings that do not start with C<tag.>.

=item * Request: F<request.yaml#/definitions/DeviceSettings>

=item * Response: C<204 NO CONTENT>

=back

=head3 C<DELETE /device/:device_id_or_serial_number/settings/:key>

=over 4

=item * User requires the read/write role for settings that start with C<tag.>, and admin
otherwise.

=item * Response: C<204 NO CONTENT>

=back

=head3 C<POST /device/:device_id_or_serial_number/validation/:validation_id>

Does not store validation results.

=over 4

=item * User requires the read-only role

=item * Request: F<device_report.yaml#/definitions/DeviceReport>

=item * Response: F<response.yaml#/definitions/ValidationResults>

=back

=head3 C<POST /device/:device_id_or_serial_number/validation_plan/:validation_plan_id>

Does not store validation results.

=over 4

=item * User requires the read-only role

=item * Request: F<device_report.yaml#/definitions/DeviceReport>

=item * Response: F<response.yaml#/definitions/ValidationResults>

=back

=head3 C<< GET /device/:device_id_or_serial_number/validation_state?status=<pass|fail|error>&status=... >>

Accepts the query parameter C<status>, indicating the desired status(es)
to search for (one of C<pass>, C<fail>, C<error>). Can be used more than once.

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/ValidationStatesWithResults>

=back

=head3 C<GET /device/:device_id_or_serial_number/interface>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DeviceNics>

=back

=head3 C<GET /device/:device_id_or_serial_number/interface/:interface_name>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DeviceNic>

=back

=head3 C<GET /device/:device_id_or_serial_number/interface/:interface_name/:field>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/DeviceNicField>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
