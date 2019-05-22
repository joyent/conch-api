package Conch::Route::DeviceReport;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::DeviceReport

=head1 METHODS

=head2 routes

Sets up the routes for /device_report:

=cut

sub routes {
    my $class = shift;
    my $device_report = shift; # secured, under /device_report

    # POST /device_report
    $device_report->post('/')->to('device_report#validate_report');

    # chainable action that looks up device_report_id, saves a device_report_rs,
    # and checks device permissions
    my $with_device_report_and_device = $device_report
        # extract and look up device_report_id from the path and device_id from the device_report
        ->under('/<device_report_id:uuid>')->to('device_report#find_device_report')
        # check the device (and permissions) from the stashed device_id
        ->under('/')->to('device#find_device');

    # GET /device_report/:device_report_id
    $with_device_report_and_device->get('/')->to('device_report#get');
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<POST /device_report>

=over 4

=item * Request: device_report.yaml

=item * Response: response.yaml#/ReportValidationResults

=back

=head3 C<GET /device_report/:device_report_id>

=over 4

=item * Response: response.yaml#/DeviceReportRow

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
