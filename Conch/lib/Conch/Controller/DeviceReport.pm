=pod

=head1 NAME

Conch::Controller::DeviceReport

=head1 METHODS

=cut

package Conch::Controller::DeviceReport;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';
use Storable 'dclone';

use Try::Tiny;

use Conch::Legacy::Schema;
use Conch::Legacy::Control::DeviceReport 'record_device_report';
use Conch::Legacy::Control::Device::Validation 'validate_device';
use Conch::Legacy::Data::Report::Switch;
use Conch::Legacy::Data::Report::Server;

use Conch::Models;

=head2 process

Processes the device report using the Legacy report code base

=cut

sub process ($c) {
	my $raw_report = $c->req->json;

	my ( $device_report, $errs, $validation_plan );
	try {
		if ( $raw_report->{device_type} && $raw_report->{device_type} eq "switch" )
		{
			$device_report   = Conch::Legacy::Data::Report::Switch->new($raw_report);
			$validation_plan = Conch::Model::ValidationPlan->lookup_by_name(
				'Conch v1 Legacy Plan: Switch');
		}
		else {
			$device_report   = Conch::Legacy::Data::Report::Server->new($raw_report);
			$validation_plan = Conch::Model::ValidationPlan->lookup_by_name(
				'Conch v1 Legacy Plan: Server');
		}
	}
	catch {
		$errs = join( "; ", map { $_->message } $_->errors );
		$c->app->log_unparsable_report( $raw_report, $errs );
	};
	return $c->status( 400, { error => $errs } ) if $errs;

	my $aux_report = dclone($raw_report);
	for my $attr ( keys %{ $device_report->pack } ) {
		delete $aux_report->{$attr};
	}
	if ( %{$aux_report} ) {
		$device_report->{aux} = $aux_report;
	}

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

	my ( $device, $report_id ) = record_device_report( $schema, $device_report );

	my $features = $c->app->config('features') || {};

	if ( $features->{new_validation} && $validation_plan) {
		Conch::Model::ValidationState->run_validation_plan(
			$device->id, $validation_plan->id, $raw_report );
	}

	my $validation_result =
		validate_device( $schema, $device, $device_report, $report_id,
		$c->app->log );

	$c->status( 200, $validation_result );
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
