=pod

=head1 NAME

Conch::Controller::DeviceValidation

=head1 METHODS

=cut

package Conch::Controller::DeviceValidation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;
use List::Util qw(notall any);

=head2 list_validation_states

Get latest validation states for a device

=cut

sub list_validation_states ($c) {
	my @statuses;
	@statuses = map { lc($_) } split /,\s*/, $c->param('status')
		if $c->param('status');

	if (
		@statuses
		&& notall {
			my $a = $_;
			any { $_ eq $a } qw( pass fail error )
		}
		@statuses
		)
	{
		return $c->status(
			400,
			{
				error =>
					"'status' query parameter must be any of 'pass', 'fail', or 'error'."
			}
		);
	}

	my $device = $c->stash('current_device');

	my $validation_state_groups =
		Conch::Model::ValidationState->latest_completed_grouped_states_for_device(
		$device->id, @statuses );

	my @output = map {
		{ $_->{state}->TO_JSON->%*, results => $_->{results} };
	} @$validation_state_groups;

	$c->status( 200, \@output );
}

=head2 get_validation_state

Get validation states for a device

=cut

sub get_validation_state ($c) {
	my $device = $c->stash('current_device');

	my $validation_state_id = $c->param("validation_state_id");

	my $validation_state =
		Conch::Model::ValidationState->lookup_with_device( $validation_state_id,
		$device->id );

	return $c->status(
		404,
		{
			error =>
				"No Validation State ID $validation_state_id is associated with Device"
		}
	) unless $validation_state;

	$c->status( 200, $validation_state );
}

=head2 validate

Validate the device gainst the specified validation.

B<DOES NOT STORE VALIDATION RESULTS>.

This is useful for testing and evaluating Validation Plans against a given
device.

=cut

sub validate ($c) {

	my $device    = $c->stash('current_device');
	my $device_id = $device->id;

	my $validation_id = $c->param("validation_id");
	my $validation    = Conch::Model::Validation->lookup($validation_id);
	return $c->status( 404, { error => "Validation $validation_id not found" } )
		unless $validation;

	my $data = $c->req->json;
	my $validation_results =
		$validation->run_validation_for_device( $device, $data );

	$c->status( 200, $validation_results );
}

=head2 run_validation_plan

Validate the device gainst the specified Validation Plan.

B<DOES NOT STORE VALIDATION RESULTS>.

This is useful for testing and evaluating Validation Plans against a given
device.

=cut

sub run_validation_plan ($c) {
	my $device    = $c->stash('current_device');
	my $device_id = $device->id;

	my $plan_id         = $c->param("validation_plan_id");
	my $validation_plan = Conch::Model::ValidationPlan->lookup($plan_id);
	return $c->status( 404, { error => "Validation Plan '$plan_id' not found" } )
		unless $validation_plan;

	my $data = $c->req->json;
	my $results = $validation_plan->run_validations( $device, $data );

	$c->status( 200, $results );
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
