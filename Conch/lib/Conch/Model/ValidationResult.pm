=pod

=head1 NAME

Conch::Model::ValidationResult

=head1 METHODS

=cut

package Conch::Model::ValidationResult;
use Mojo::Base -base, -signatures;

my $attrs = [
	qw(id device_id hardware_product_id validation_id message hint status
		category component_id)
];
has $attrs;

=head2 output_hash

Render as a hashref for output

=cut
sub output_hash ($self) {
	return {
		id                  => $self->id,
		device_id           => $self->device_id,
		hardware_product_id => $self->hardware_product_id,
		validation_id       => $self->validation_id,
		message             => $self->message,
		hint                => $self->hint,
		status              => $self->status,
		category            => $self->category,
		component_id        => $self->component_id,
	};
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
