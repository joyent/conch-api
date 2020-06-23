package Conch::Route::DeviceReport;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::DeviceReport

=head1 METHODS

=head2 routes

Sets up the routes for /device_report.

=cut

sub routes {
    my $class = shift;
    my $device_report = shift; # secured, under /device_report

    $device_report
        # POST /device_report
        ->under(['POST'], '/')->to('device_report#process')
        # POST /device_report?no_save_db=1
        ->post('/')->to('device_report#validate_report');

    # chainable action that looks up device_report_id, saves a device_report_rs,
    # and checks device access authorization
    my $with_device_report_and_device = $device_report
        # extract and look up device_report_id from the path and device_id from the device_report
        ->under('/<device_report_id:uuid>')->to('device_report#find_device_report')
        # check the device (and the user's authorization to access it) from the stashed device_id
        ->under('/')->to('device#find_device');

    # GET /device_report/:device_report_id
    $with_device_report_and_device->get('/')->to('device_report#get');
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<POST /device_report>

Submits a device report for processing. The device must already exist.
Device data will be updated in the database.

=over 4

=item * The authenticated user must have previously registered the relay being used for the
report submission (as indicated via C<#/relay/serial> in the report).

=item * Controller/Action: L<Conch::Controller::DeviceReport/process>

=item * Request: F<request.yaml#/definitions/DeviceReport>

=item * Response: F<response.yaml#/definitions/ValidationStateWithResults>

=back

=head2 C<POST /device_report?no_update_db=1>

Submits a device report for processing. Device data will B<not> be updated in the database;
only validations will be run.

=over 4

=item * Controller/Action: L<Conch::Controller::DeviceReport/validate_report>

=item * Request: F<request.yaml#/definitions/DeviceReport>

=item * Response: F<response.yaml#/definitions/ReportValidationResults>

=back

=head2 C<GET /device_report/:device_report_id>

=over 4

=item * User requires the read-only role, as described in L<Conch::Route::Device/routes>.

=item * Controller/Action: L<Conch::Controller::DeviceReport/get>

=item * Response: F<response.yaml#/definitions/DeviceReportRow>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
