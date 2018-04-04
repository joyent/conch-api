=pod

=head1 NAME

Conch::ValidationSystem

=head1 METHODS

=cut

package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
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

Load two validation plans: 'Conch v1 Legacy Plan: Switch' and 'Conch v1 Legacy
Plan: Server'.

These validation plans contain validations that correspond to the validation
logic run in previous version of Conch (called 'v1' here). All versions of the 

This method can be removed once the infrastructure for building, managing, and
associating validation plans with devices through Orchestration is available to
users.

=cut

sub load_legacy_plans ( $class, $logger = Mojo::Log->new ) {

	my $switch_plan =
		Conch::Model::ValidationPlan->lookup_by_name(
		'Conch v1 Legacy Plan: Switch');

	unless ($switch_plan) {
		$switch_plan = Conch::Model::ValidationPlan->create(
			'Conch v1 Legacy Plan: Switch',
			'Validation plan containing all validations run in Conch v1 on switches'
		);
		$logger->debug( "Created validation plan " . $switch_plan->name );
	}

	my @switch_validations =
		qw( bios_firmware_version cpu_count cpu_temperature product_name
		dimm_count ram_total );
	for my $name (@switch_validations) {
		my $validation =
			Conch::Model::Validation->lookup_by_name_and_version( $name, 1 );
		if ($validation) {
			$switch_plan->add_validation($validation);
		}
		else {
			$logger->warn( "Could not find Validation name $name, version 1"
					. " to load for Legacy Switch Validation Plan" );
		}
	}

	my $server_plan =
		Conch::Model::ValidationPlan->lookup_by_name(
		'Conch v1 Legacy Plan: Server');
	unless ($server_plan) {
		$server_plan =
			Conch::Model::ValidationPlan->create( 'Conch v1 Legacy Plan: Server',
			'Validation plan containing all validations run in Conch v1 on servers' );
		$logger->debug( "Created validation plan " . $server_plan->name );
	}

	my @server_validations = qw( bios_firmware_version cpu_count cpu_temperature
		product_name dimm_count disk_smart_status disk_temperature links_up
		nics_num ram_total sas_hdd_num sas_ssd_num slog_slot switch_peers
		usb_hdd_num );
	for my $name (@server_validations) {
		my $validation =
			Conch::Model::Validation->lookup_by_name_and_version( $name, 1 );
		if ($validation) {
			$server_plan->add_validation($validation);
		}
		else {
			$logger->warn( "Could not find Validation name $name, version 1"
					. " to load for Legacy Server Validation Plan" );
		}
	}

	return ( $switch_plan, $server_plan );
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
