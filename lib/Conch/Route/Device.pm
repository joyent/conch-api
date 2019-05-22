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

    # POST /device/:device_serial_number
    $device->post('/:device_serial_number')->to('device_report#process');

    # GET /device?key=:value
    $device->get('/')->to('device#lookup_by_other_attribute');

    {
        # chainable action that extracts and looks up device_id from the path
        my $with_device = $device->under('/:device_id')->to('device#find_device');

        # GET /device/:device_id
        $with_device->get('/')->to('device#get');

        # GET /device/:device_id/pxe
        $with_device->get('/pxe')->to('device#get_pxe');

        # GET /device/:device_id/phase
        $with_device->get('/phase')->to('device#get_phase');

        # POST /device/:device_id/graduate
        $with_device->post('/graduate')->to('device#graduate');
        # POST /device/:device_id/triton_setup
        $with_device->post('/triton_setup')->to('device#set_triton_setup');
        # POST /device/:device_id/triton_uuid
        $with_device->post('/triton_uuid')->to('device#set_triton_uuid');
        # POST /device/:device_id/triton_reboot
        $with_device->post('/triton_reboot')->to('device#set_triton_reboot');
        # POST /device/:device_id/asset_tag
        $with_device->post('/asset_tag')->to('device#set_asset_tag');
        # POST /device/:device_id/validated
        $with_device->post('/validated')->to('device#set_validated');
        # POST /device/:device_id/phase
        $with_device->post('/phase')->to('device#set_phase');

        {
            my $with_device_location = $with_device->any('/location');
            $with_device_location->to({ controller => 'device_location' });

            # GET /device/:device_id/location
            $with_device_location->get('/')->to('#get');
            # POST /device/:device_id/location
            $with_device_location->post('/')->to('#set');
            # DELETE /device/:device_id/location
            $with_device_location->delete('/')->to('#delete');
        }

        {
            my $with_device_settings = $with_device->any('/settings');
            $with_device_settings->to({ controller => 'device_settings' });

            # GET /device/:device_id/settings
            $with_device_settings->get('/')->to('#get_all');
            # POST /device/:device_id/settings
            $with_device_settings->post('/')->to('#set_all');

            my $with_device_settings_with_key = $with_device_settings->any('/#key');
            # GET /device/:device_id/settings/#key
            $with_device_settings_with_key->get('/')->to('#get_single');
            # POST /device/:device_id/settings/#key
            $with_device_settings_with_key->post('/')->to('#set_single');
            # DELETE /device/:device_id/settings/#key
            $with_device_settings_with_key->delete('/')->to('#delete_single');
        }

        # POST /device/:device_id/validation/:validation_id
        $with_device->post('/validation/<validation_id:uuid>')->to('device_validation#validate');
        # POST /device/:device_id/validation_plan/:validation_plan_id
        $with_device->post('/validation_plan/<validation_plan_id:uuid>')->to('device_validation#run_validation_plan');
        # GET /device/:device_id/validation_state?status=<pass|fail|error>&status=...
        $with_device->get('/validation_state')->to('device_validation#list_validation_states');

        {
            my $with_device_interface = $with_device->any('/interface');
            $with_device_interface->to({ controller => 'device_interface' });

            # GET /device/:device_id/interface
            $with_device_interface->get('/')->to('#get_all');

            # chainable action that extracts and looks up interface_name from the path
            my $with_interface_name = $with_device_interface->under('/#interface_name')->to('#find_device_interface');

            # GET /device/:device_id/interface/#interface_name
            $with_interface_name->get('/')->to('#get_one');

            # GET /device/:device_id/interface/#interface_name/:field
            $with_interface_name->get('/:field', [ field => [ $app->db_device_nics->fields ] ])
                ->to('#get_one_field');
        }
    }
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<POST /device/:device_serial_number>

=over 4

=item * Request: device_report.yaml#/DeviceReport_v3.0.0

=item * Response: response.yaml#/ValidationStateWithResults

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

=item * Response: response.yaml#/Devices

=back

=head3 C<GET /device/:device_id>

=over 4

=item * Response: response.yaml#/DetailedDevice

=back

=head3 C<GET /device/:device_id/pxe>

=over 4

=item * Response: response.yaml#/DevicePXE

=back

=head3 C<GET /device/:device_id/phase>

=over 4

=item * Response: response.yaml#/DevicePhase

=back

=head3 C<POST /device/:device_id/graduate>

=over 4

=item * Request: request.yaml#/Null

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id/triton_setup>

=over 4

=item * Request: request.yaml#/Null

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id/triton_uuid>

=over 4

=item * Request: request.yaml#/DeviceTritonUuid

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id/triton_reboot>

=over 4

=item * Request: request.yaml#/Null

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id/asset_tag>

=over 4

=item * Request: request.yaml#/DeviceAssetTag

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id/validated>

=over 4

=item * Request: request.yaml#/Null

=item * Response: Redirect to the updated device

=back

=head3 C<POST /device/:device_id/phase>

=over 4

=item * Request: request.yaml#/DevicePhase

=item * Response: Redirect to the updated device

=back

=head3 C<GET /device/:device_id/location>

=over 4

=item * Response: response.yaml#/DeviceLocation

=back

=head3 C<POST /device/:device_id/location>

=over 4

=item * Request: request.yaml#/DeviceLocationUpdate

=item * Response: Redirect to the updated device

=back

=head3 C<DELETE /device/:device_id/location>

=over 4

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /device/:device_id/settings>

=over 4

=item * Response: response.yaml#/DeviceSettings

=back

=head3 C<POST /device/:device_id/settings>

=over 4

=item * Requires read/write device authorization

=item * Request: request.yaml#/DeviceSettings

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /device/:device_id/settings/:key>

=over 4

=item * Response: response.yaml#/DeviceSetting

=back

=head3 C<POST /device/:device_id/settings/:key>

=over 4

=item * Requires read/write device authorization

=item * Request: request.yaml#/DeviceSettings

=item * Response: C<204 NO CONTENT>

=back

=head3 C<DELETE /device/:device_id/settings/:key>

=over 4

=item * Requires read/write device authorization

=item * Response: C<204 NO CONTENT>

=back

=head3 C<POST /device/:device_id/validation/:validation_id>

Does not store validation results.

=over 4

=item * Request: device_report.yaml

=item * Response: response.yaml#/ValidationResults

=back

=head3 C<POST /device/:device_id/validation_plan/:validation_plan_id>

Does not store validation results.

=over 4

=item * Request: device_report.yaml

=item * Response: response.yaml#/ValidationResults

=back

=head3 C<< GET /device/:device_id/validation_state?status=<pass|fail|error>&status=... >>

Accepts the query parameter C<status>, indicating the desired status(es)
to search for (one of C<pass>, C<fail>, C<error>). Can be used more than once.

=over 4

=item * Response: response.yaml#/ValidationStatesWithResults

=back

=head3 C<GET /device/:device_id/interface>

=over 4

=item * Response: response.yaml#/DeviceNics

=back

=head3 C<GET /device/:device_id/interface/:interface_name>

=over 4

=item * Response: response.yaml#/DeviceNic

=back

=head3 C<GET /device/:device_id/interface/:interface_name/:field>

=over 4

=item * Response: response.yaml#/DeviceNicField

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
