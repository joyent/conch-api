=pod

=head1 NAME

Conch::Controller::DeviceValidation

=head1 METHODS

=cut

package Conch::Controller::DeviceValidation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;

=head2 validate

Validate the device gainst the specified validation.

B<DOES NOT STORE VALIDATION RESULTS>.

This is useful for testing and evaluating Validation Plans against a given
device.

=cut

sub validate ($c) {
	my $device         = $c->stash('current_device');
	my $device_id      = $device->id;

	my $validation_id = $c->param("validation_id");
	my $validation    = Conch::Model::Validation->lookup($validation_id);
	$c->status( 404, { error => "Validation $validation_id not found" } )
		unless $validation;

	my $validator = $validation->build_validation_for_device($device);
	my $data      = $c->req->json;
	$validator->run($data);
	my $validation_results = $validator->validation_results;

	$c->status( 200, $validation_results );
}

=head2 run_validation_plan

Validate the device gainst the specified Validation Plan.

B<DOES NOT STORE VALIDATION RESULTS>.

This is useful for testing and evaluating Validation Plans against a given
device.

=cut

sub run_validation_plan ($c) {
	my $device         = $c->stash('current_device');
	my $device_id      = $device->id;

	my $plan_id         = $c->param("validation_plan_id");
	my $validation_plan = Conch::Model::ValidationPlan->lookup($plan_id);
	return $c->status( 404, { error => "Validation Plan '$plan_id' not found" } )
		unless $validation_plan;

	my $data = $c->req->json;
	my $results = $validation_plan->run_validations( $device, $data );

	$c->status( 200, $results );
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
