=pod

=head1 NAME

Conch::ValidationSystem

=head1 METHODS

=cut

package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
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

sub load_validations ( $class, $logger ) {
	my $num_loaded_validations = 0;
	for my $m ( Submodules->find('Conch::Validation') ) {
		next if $m->{Module} eq 'Conch::Validation';

		$m->require;

		my $validation_module = $m->{Module};

		my $validation = $validation_module->new();
		unless ( $validation->isa('Conch::Validation') ) {
			$logger->info(
				"$validation_module must be a sub-class of Conch::Validation. Skipping."
			);
			next;
		}

		unless ( $validation->name
			&& $validation->version
			&& $validation->description )
		{
			$logger->info(
				"$validation_module must define the 'name', 'version, and 'description'"
					. " attributes with values. Skipping." );
			next;
		}

		$validation->log(sub { return $logger });

		my $trimmed_description = $validation->description;
		$trimmed_description =~ s/^\s+//;
		$trimmed_description =~ s/\s+$//;

		my $v = Conch::Model::Validation->upsert(
			$validation->name,
			$validation->version,
			$trimmed_description,
			$validation_module,
		);
		if($v) {
			$num_loaded_validations++;
			$logger->info("Loaded $validation_module");
		}
	}
	return $num_loaded_validations;
}

=head2 load_validation_plans

Takes an array ref of structured hash refs and creates a validation plan (if it doesn't
exist) and adds specified validation plans for each of the structured hashes.

Each hash has the structure

	{
		name        => 'Validation plan name',
		description => 'Validatoin plan description',
		validations => [
			{ name => 'validation_name', version => 1 }
		]
	}

If a validation plan by the name already exists, all associations to
validations are dropped before the specified validations are added. This allows
modifying the membership of the validation plans.

Returns the list of validations plan objects.

I<Note: This is mostly used by the test harness>

=cut

sub load_validation_plans ( $class, $plans, $logger ) {
	my @plans;
	for my $p ( $plans->@* ) {
		my $plan = Conch::Model::ValidationPlan->lookup_by_name( $p->{name} );

		unless ($plan) {
			$plan =
				Conch::Model::ValidationPlan->create( $p->{name}, $p->{description}, );
			$logger->info( "Created validation plan " . $plan->name );
		}
		$plan->drop_validations;
		for my $v ( $p->{validations}->@* ) {
			my $validation =
				Conch::Model::Validation->lookup_by_name_and_version( $v->{name},
				$v->{version} );
			if ($validation) {
				$plan->add_validation($validation);
			}
			else {
				$logger->info(
					"Could not find Validation name $v->{name}, version $v->{version}"
						. " to load for "
						. $plan->name );
			}
		}
		$logger->info( "Loaded validation plan " . $plan->name );
		push @plans, $plan;
	}
	return @plans;
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
