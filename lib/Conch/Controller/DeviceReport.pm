=pod

=head1 NAME

Conch::Controller::DeviceReport

=head1 METHODS

=cut

package Conch::Controller::DeviceReport;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;
use Conch::Legacy::Control::DeviceReport 'record_device_report';

=head2 process

Processes the device report using the Legacy report code base

=cut

sub process ($c) {
	my $device_report = $c->validate_input('DeviceReport');
	return if not $device_report;
	my $raw_report = $c->req->body;

	my $maybe_hw;

	if ( $device_report->{device_type}
		&& $device_report->{device_type} eq "switch" )
	{
		$maybe_hw = Conch::Model::HardwareProduct->lookup_by_name(
			$device_report->{product_name}
		);
		return $c->status(409, {
			error => "Hardware product name '".$device_report->{product_name}."' does not exist"
		}) unless ($maybe_hw);

	} else {
		$maybe_hw = Conch::Model::HardwareProduct->lookup_by_sku(
			$device_report->{sku}
		);

		return $c->status(409, {
			error => "Hardware product SKU '".$device_report->{sku}."' does not exist"
		}) unless ($maybe_hw);

	}

	# Use the old device report recording and device validation code for now.
	# This will be removed when OPS-RFD 22 is implemented
	my ( $device, $report_id ) = record_device_report(
		$c->schema,
		$device_report,
		$raw_report
	);

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

	# [2018-07-16 sungo] - As we grow this logic to be smarter and more
	# interesting, it will probably be ok to not find a validation plan. For
	# now, everything needs to validate using one of the legacy plans. It's a
	# super big problem if they don't exist so we explode.
	unless($validation_plan) {
		Mojo::Exception->throw(__PACKAGE__.": Could not find a validation plan");
	}

	my $validation_state =
		Conch::Model::ValidationState->run_validation_plan( $device->id,
		$validation_plan->id, $device_report );

	# this uses the DBIC object from record_device_report to do the update
	$device->update( { health => uc( $validation_state->status ) } );

	$c->status( 200, $validation_state );
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
