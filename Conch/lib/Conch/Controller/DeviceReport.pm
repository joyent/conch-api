=pod

=head1 NAME

Conch::Controller::DeviceReport

=head1 METHODS

=cut

package Conch::Controller::DeviceReport;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Try::Tiny;

use Conch::Legacy::Schema;
use Conch::Legacy::Control::DeviceReport 'record_device_report';

use Conch::Models;

=head2 process

Processes the device report using the Legacy report code base

=cut

sub process ($c) {
	my $device_report = $c->validate_input('DeviceReport') or return;
	my $raw_report = $c->req->body;

	my $hw_product_name = $device_report->{product_name};
	my $maybe_hw =
		Conch::Model::HardwareProduct->lookup_by_name($hw_product_name);

	unless ($maybe_hw) {
		return $c->status(
			409,
			{
				error => "Hardware Product '$hw_product_name' does not exist."
			}
		);
	}

	# Use the old device report recording and device validation code for now.
	# This will be removed when OPS-RFD 22 is implemented
	my $pg = Conch::Pg->new;
	my $schema =
		Conch::Legacy::Schema->connect( $pg->dsn, $pg->username, $pg->password );

	my ( $device, $report_id ) = record_device_report( $schema, $device_report, $raw_report );

	my $validation_plan;
	if ( $device_report->{device_type}
		&& $device_report->{device_type} eq "switch" )
	{
		$validation_plan = Conch::Model::ValidationPlan->lookup_by_name(
			'Conch v1 Legacy Plan: Switch');
	}
	else {
		$validation_plan = Conch::Model::ValidationPlan->lookup_by_name(
			'Conch v1 Legacy Plan: Server');
	}

	my $validation_state =
		Conch::Model::ValidationState->run_validation_plan( $device->id,
		$validation_plan->id, $device_report );

	# this uses the DBIC object from record_device_report to do the update
	$device->update( { health => uc( $validation_state->status ) } );

	$c->status( 200, $validation_state );
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
