=pod

=head1 NAME

Conch::ValidationSystem

=head1 METHODS

=cut

package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
use Conch::Minion;
use Mojo::Log;
use Mojo::Exception;
use Submodules;

use Conch::Model::ValidationState;
use Conch::Pg;

=head2 load_validations

Load all Conch::Validation::* sub-classes into the database with
Conch::Model::Validation. This uses upsert, so existing Validation models will
only be modified if attributes change.

Returns the number of new or changed validations loaded.

=cut

sub load_validations ( $class, $logger = Mojo::Log->new ) {
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

=head2 load_legacy_plans

=cut

sub load_legacy_plans ( $class, $logger = Mojo::Log->new ) {

	my $switch_plan =
		Conch::Model::ValidationPlan->lookup_by_name(
		'Conch v1 Legacy Plan: Switch');
	$switch_plan ||=
		Conch::Model::ValidationPlan->create( 'Conch v1 Legacy Plan: Switch',
		'Validation plan containing all validations run in Conch v1 on switches' );

	my @switch_validations =
		qw( bios_firmware_version cpu_count cpu_temperature product_name
		dimm_count ram_total );
	for my $name (@switch_validations) {
		my $validation =
			Conch::Model::Validation->lookup_by_name_and_version( $name, 1 );
		$switch_plan->add_validation($validation) if $validation;
	}

	my $server_plan =
		Conch::Model::ValidationPlan->lookup_by_name(
		'Conch v1 Legacy Plan: Server');
	$server_plan ||=
		Conch::Model::ValidationPlan->create( 'Conch v1 Legacy Plan: Server',
		'Validation plan containing all validations run in Conch v1 on servers' );

	my @server_validations = qw( bios_firmware_version cpu_count cpu_temperature
		product_name dimm_count disk_smart_status disk_temperature links_up
		nics_num ram_total sas_hdd_num sas_ssd_num slog_slot switch_peers
		usb_hdd_num );
	for my $name (@server_validations) {
		my $validation =
			Conch::Model::Validation->lookup_by_name_and_version( $name, 1 );
		$server_plan->add_validation($validation) if $validation;
	}
}

=head2 run_validation_plan

Returns a new validation state

=cut

sub run_validation_plan ( $class, $device_id, $validation_plan_id, $data ) {

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

	my $latest_state =
		Conch::Model::ValidationState->latest_completed_state( $device_id,
		$validation_plan_id );

	my %latest_results =
		map { ( $_->comparison_hash => $_->id ) }
		$latest_state->validation_results->@*
		if $latest_state;

	my $minion = Conch::Minion->new;
	my @validation_job_ids =
		map {
		$minion->enqueue( validation =>
				[ $_, $device_id, $validation_state->id, {%latest_results}, $data ] );
		} $validations->@*;

	$minion->enqueue(
		commit_validation_state => [ $validation_state->id ],
		{ parents => \@validation_job_ids }
	);

	return $validation_state;
}

=head2 start_tasks

Start the Minion tasks for processing validations

=cut

sub start_tasks ( $class ) {
	Conch::Minion->new->add_task(
		validation => sub {
			my ( $job, $validation_id, $device_id,
				$validation_state_id, $latest_results, $data )
				= @_;
			$job->on( failed => sub { use DDP; p $_[1]; } );

			my $validation = Conch::Model::Validation->lookup($validation_id);
			$job->fail("Unable to find Validation '$validation_id'")
				unless $validation;
			my $device = Conch::Model::Device->lookup($device_id);
			$job->fail("Unable to find Device '$device_id'")
				unless $device;

			my @new_results =
				$validation->run_validation_for_device( $device, $data )->@*;

			my $state = Conch::Model::ValidationState->lookup($validation_state_id);

			my @result_ids;
			for my $result (@new_results) {
				if ( my $last_result_id =
					$latest_results->{ $result->comparison_hash } )
				{
					$state->add_validation_result($last_result_id);
					push @result_ids, $last_result_id;
				}
				else {
					$state->add_validation_result( $result->record );
					push @result_ids, $result->id;
				}
			}

			$job->finish( \@result_ids );
		}
	);

	Conch::Minion->new->add_task(
		commit_validation_state => sub {
			my ( $job, $validation_state_id ) = @_;

			my $validation_state =
				Conch::Model::ValidationState->lookup($validation_state_id);
			$job->fail( "Unable to find Validation State '$validation_state_id'."
					. " to mark as completed" )
				unless $validation_state;
			$validation_state->mark_completed();
			$job->finish();
		}
	);
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
