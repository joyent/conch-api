=pod

=head1 NAME

Conch::Validations

=head1 METHODS

=cut

package Conch::Validations;

use Mojo::Base -base, -signatures;
use Submodules;

=head2 load

Load all Conch::Validation::* sub-classes into the database with
Conch::Model::Validation. This uses upsert, so existing Validation models will
only be modified if attributes change.

Returns the number of validations loaded.

=cut

sub load ( $class, $logger ) {
	my $num_loaded = 0;
	for my $m ( Submodules->find('Conch::Validation') ) {
		my $ns = $m->{Module};

		next if $ns eq 'Conch::Validation';

		$m->require;

		my $validation = $ns->new();
		$num_loaded++ if Conch::Model::Validation->upsert(
			$validation->name,
			$validation->version,
			$validation->description,
			$ns,
		);
		$logger->info("Loaded validation: $ns");
	}
	return $num_loaded;
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
