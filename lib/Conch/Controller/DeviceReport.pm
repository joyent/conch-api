=pod

=head1 NAME

Conch::Controller::DeviceReport

=head1 METHODS

=cut

package Conch::Controller::DeviceReport;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;
use Conch::Legacy::Control::DeviceReport 'record_device_report';

with 'Conch::Role::MojoLog';

=head2 process

Processes the device report using the Legacy report code base

=cut

sub process ($c) {
	my $device_report = $c->validate_input('DeviceReport');
	return if not $device_report;
	my $raw_report = $c->req->body;
	my $schema = $c->schema;

	my $hw;
	if ($device_report->{device_type} && $device_report->{device_type} eq "switch") {
		$hw = $schema->resultset('HardwareProduct')->find({
			name => $device_report->{product_name}
		});

		$hw or return $c->render(status => 409, json => {
			error => "Hardware product name '".$device_report->{product_name}."' does not exist"
		});

	} else {
		$hw = $schema->resultset('HardwareProduct')->find({
			sku => $device_report->{sku}
		});

		if(not $hw) {
			$c->log->debug("Could not find hardware product by SKU, falling back to legacy_product_name");
		    $hw = $schema->resultset('HardwareProduct')->find({
				legacy_product_name => $device_report->{product_name}
			});

			$hw or return $c->render(status => 409, json => {
				error => "Hardware product not found by sku '".$device_report->{sku}.
					"' or by legacy name '".$device_report->{product_name}."'."
			});
		}
	}

	$hw->hardware_product_profile or return $c->render(status => 409, json => {
		error => "Hardware product '".$hw->name."' exists but does not have a hardware profile",
	});


	# Use the old device report recording and device validation code for now.
	# This will be removed when OPS-RFD 22 is implemented
	my ( $device, $report_id ) = record_device_report(
		$c->schema,
		$device_report,
		$raw_report,
		$hw,
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
