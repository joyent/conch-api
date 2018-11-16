package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
use Submodules;
use Mojo::Util 'trim';

has 'schema';
has 'log';

=pod

=head1 NAME

Conch::ValidationSystem

=head1 METHODS

=head2 load_validations

Load all Conch::Validation::* sub-classes into the database.
Existing validation records will only be modified if attributes change.

Returns the number of new or changed validations loaded.

=cut

sub load_validations ($self) {
	my $num_loaded_validations = 0;
	for my $m ( Submodules->find('Conch::Validation') ) {
		next if $m->{Module} eq 'Conch::Validation';

		$m->require;

		my $validation_module = $m->{Module};

		my $validation = $validation_module->new();
		unless ( $validation->isa('Conch::Validation') ) {
			$self->log->info(
				"$validation_module must be a sub-class of Conch::Validation. Skipping."
			);
			next;
		}

		unless ( $validation->name
			&& $validation->version
			&& $validation->description )
		{
			$self->log->info(
				"$validation_module must define the 'name', 'version, and 'description'"
					. " attributes with values. Skipping." );
			next;
		}

		if (my $validation_row = $self->schema->resultset('validation')->find({
				name => $validation->name,
				version => $validation->version,
			})) {
			$validation_row->set_columns({
				description => trim($validation->description),
				module => $validation_module,
			});
			if ($validation_row->is_changed) {
				$validation_row->update({ updated => \'now()' });
				$num_loaded_validations++;
				$self->log->info("Updated entry for $validation_module");
			}
		}
		else {
			$self->schema->resultset('validation')->create({
				name => $validation->name,
				version => $validation->version,
				description => trim($validation->description),
				module => $validation_module,
			});
			$num_loaded_validations++;
			$self->log->info("Created entry for $validation_module");
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
