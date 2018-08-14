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

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
