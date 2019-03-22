package Conch::Route::DeviceReport;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::DeviceReport

=head1 METHODS

=head2 routes

Sets up the routes for /device_report:

    GET     /device_report/:device_report_id

=cut

sub routes {
    my $class = shift;
    my $device_report = shift; # secured, under /device_report

    # chainable action that extracts and looks up device_report_id from the path
    # and device_id from the device_report
    my $with_device_report = $device_report->under('/:device_report_id')
        ->to('device_report#find_device_report');

    # chainable action that checks the device from the stashed device_id
    my $with_device_report_and_device = $with_device_report->get->under('/')
        ->to('device#find_device');

    # GET /device_report/:device_report_id
    $with_device_report_and_device->get('/')->to('device_report#get');
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
