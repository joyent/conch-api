=pod

=head1 NAME

Conch::Class::DeviceDetailed

=head1 METHODS

=cut

package Conch::Class::DeviceDetailed;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

=head2 device

=head2 lastest_report

=head2 validation_results

=head2 nics

=head2 location

=cut

has [
	qw(
		device
		latest_report
		validation_results
		nics
		location
		)
];


=head2 TO_JSON

=cut

sub TO_JSON {
	my $self    = shift;
	my $device  = $self->device->as_v1;
	my @results = map { $_->{validation} } $self->validation_results->@*;

	my $details = {
		latest_report => $self->latest_report,
		validations   => \@results,
		nics          => $self->nics,
		location      => $self->location && $self->location->TO_JSON
	};
	return { %$device, %$details };
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
