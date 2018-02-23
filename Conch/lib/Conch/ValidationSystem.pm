=pod

=head1 NAME

Conch::ValidationSystem

=head1 METHODS

=cut

package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
use Minion;
use Mojo::Log;
use Mojo::Exception;
use Submodules;

use Conch::Model::ValidationState;
use Conch::Pg;

has 'minion' => sub { Minion->new( Pg => Conch::Pg->new ) };

=head2 load_validations

Load all Conch::Validation::* sub-classes into the database with
Conch::Model::Validation. This uses upsert, so existing Validation models will
only be modified if attributes change.

Returns the number of new or changed validations loaded.

=cut

sub load_validations ( $self, $logger = Mojo::Log->new ) {
	my $num_loaded_validations = 0;
	for my $m ( Submodules->find('Conch::Validation') ) {
		next if $m->{Module} eq 'Conch::Validation';

		$m->require;

		my $validation_module = $m->{Module};
		unless ( $validation_module->can('new') ) {
			$logger->warn("$validation_module cannot '->new'. Skipping.");
			next;
		}
		my $validation = $validation_module->new();
		unless ( $validation->isa('Conch::Validation') ) {
			$logger->warn(
				"$validation_module must be a sub-class of Conch::Validation. Skipping."
			);
			next;
		}

		unless ( $validation->name
			&& $validation->version
			&& $validation->description )
		{
			$logger->warn(
				"$validation_module must define the 'name', 'version, and 'description'"
					. " attributes with values. Skipping." );
			next;
		}

		my $trimmed_description = $validation->description;
		$trimmed_description =~ s/^\s+//;
		$trimmed_description =~ s/\s+$//;
		$num_loaded_validations++
			if Conch::Model::Validation->upsert(
			$validation->name,    $validation->version,
			$trimmed_description, $validation_module,
			) && $logger->debug("Loaded $validation_module");
	}
	return $num_loaded_validations;
}

=head2 run_validation_plan

Returns a new validation state

=cut

sub run_validation_plan ( $self, $device_id, $validation_plan_id, $data ) {

	Mojo::Exception->throw("Device ID must be defined") unless $device_id;
	Mojo::Exception->throw("Validation Plan ID must be defined")
		unless $validation_plan_id;
	Mojo::Exception->throw("Validation data must be a hashref")
		unless ref($data) eq 'HASH';

	my $device = Conch::Model::Device->lookup($device_id);

	Mojo::Exception->throw("No device exists with ID '$device_id'")
		unless $device;

	my $hw_product = $device->hardware_product;
	Mojo::Exception->throw(
		"No hardware product associated with Device '$device_id'")
		unless $hw_product;

	my $validation_plan =
		Conch::Model::ValidationPlan->lookup($validation_plan_id);
	Mojo::Exception->throw(
		"No Validation Plan found with ID '$validation_plan_id'")
		unless $validation_plan;

	my $validations = $validation_plan->validation_ids;
	Mojo::Exception->throw(
		"Validation Plan $validation_plan_id is not associated with any validations"
	) unless scalar( $validations->@* );

	my $validation_state =
		Conch::Model::ValidationState->create( $device_id, $validation_plan->id );

	my @validation_job_ids = map {
		$self->minion->enqueue(
			validation => [ $_, $device_id, $data, $validation_state->id ] );
	} $validations->@*;

	$self->minion->enqueue(
		commit_validation_state => [ $validation_state->id ],
		{ parents => \@validation_job_ids }
	);

	return $validation_state;
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
