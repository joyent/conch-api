package Conch::Validation::DimmMap;

use Mojo::Base 'Conch::Validation';

use List::Compare;
use Mojo::Log;
use JSON::PP;

has 'name'        => 'dimm_map';
has 'version'     => 1;
has 'category'    => 'RAM';
has 'description' => 'Identify any missing or misbehaving DIMMs';

sub validate {
	my ( $self, $data ) = @_;

	my $message;
	my $hint;
	my $error;

	my $dimms     = $data->{dimms};
	my $hw_spec_j = $self->hardware_product_specification;

	unless ($hw_spec_j) {
		$self->register_result(
			expected => 0,
			got      => 0,
			message  => "hardware specification requires for this validation",
		);
		return;
	}

	my $hw_spec   = decode_json $hw_spec_j;
	my $dimm_spec = $hw_spec->{chassis}->{memory}->{dimms};

	# Build array of expected DIMMs keyed off bank locators from hw spec
	my @expected_slots;
	foreach my $spec_s ($dimm_spec->@*) {
		my $slot = $spec_s->{slot};
		push @expected_slots, $slot;
	}

	# Build array of reported DIMMs keyed off bank locators from report
	my @populated_slots;
	my @empty_slots;
	foreach my $dimm ($dimms->@*) {
		my $slot = $dimm->{'memory-locator'};

		if ($dimm->{'memory-serial-number'}) {
			push @populated_slots, $slot;
		} else {
			unless (grep(/^$slot$/, @empty_slots)) {
				push @empty_slots, $slot;
			}
		}
	}

	my $lc = List::Compare->new(\@expected_slots, \@populated_slots);

	my @incorrect = $lc->get_complement();
	my @missing = $lc->get_unique();

	my $sorted_e = join(',', sort { lc($a) cmp lc($b) } @expected_slots);
	my $sorted_p = join(',', sort { lc($a) cmp lc($b) } @populated_slots);

	if (@incorrect) {
		$error = 1;
		$message .= "Wrong slot: " . join(', ', @incorrect) . "\n";
	}

	if (@missing) {
		$error = 1;
		$message .= "Missing: " . join(', ', @missing) . "\n";
	}

	$message = "DIMM map OK" unless $error;

	$self->register_result(
		expected => $sorted_e,
		got      => $sorted_p,
		message  => $message,
		hint     => "Expected: $sorted_e",
	);
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
