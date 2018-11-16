=pod

=head1 NAME

Conch::Model::ValidationResult

=head1 METHODS

=cut

package Conch::Model::ValidationResult;
use Mojo::Base -base, -signatures;

our $attrs = [
	qw(id device_id hardware_product_id validation_id message hint status
		category component_id result_order)
];
has $attrs;

=head2 new

Create a new Validation Result. Unlike other models, C<new> should be used and
then C<record> to write it to the database.

	my $result = Conch::Model::ValidationResult->new(
		device_id           => $device->id,
		validation_id       => $validation->id,
		hardware_product_id => $hardware_product_id,
		message             => 'Expected eq '1', got '2',
		category            => 'CPU',
		status              => 'fail',
		result_order        => 3
	);
	$result->record;

All unspecified attribute fields will be undef.

=cut

sub new ( $class, %args ) {
	$class->SUPER::new( %args{@$attrs} );
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
