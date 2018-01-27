package Conch::Legacy::Data::Report::Switch;

use Moose;
use MooseX::Constructor::AllErrors;
use MooseX::Types::UUID qw( UUID );
use MooseX::Storage;

use Conch::Legacy::Control::Device::Configuration;
use Conch::Legacy::Control::Device::Environment;
use Conch::Legacy::Control::Device::Inventory;
use Conch::Legacy::Control::Device::Network;

use Conch::Legacy::Data::Report::Role;

with Storage( 'format' => 'JSON' );

with 'Conch::Legacy::Data::Report::Role';

=head2 validations

Return the list of validation functions associated with this category of device
report.

=cut
sub validations {
	my $self = shift;
	return ( \&validate_system, \&validate_cpu_temp, \&validate_bios_firmware );
}

=head2 nics_count

Get number of NICs in device report

=cut
sub nics_count {
	my $self = shift;
	my @nics;
	for my $port ( keys %{ $self->media } ) {
		for my $nic ( keys %{ $self->media->{$port} } ) {
			push @nics, $nic if $self->media->{$port}->{$nic};
		}
	}
	return scalar @nics;
}

has 'product_name' => (
	required => 1,
	is       => 'ro',
	isa      => 'Str'
);

has 'serial_number' => (
	required => 1,
	is       => 'ro',
	isa      => 'Str'
);

has 'system_uuid' => (
	required => 1,
	is       => 'ro',
	isa      => UUID
);

has 'state' => (
	required => 1,
	is       => 'ro',
	isa      => 'Str'
);

has 'media' => (
	required => 1,
	is       => 'ro',
	isa      => 'HashRef[HashRef[Any]]'
);

has 'bios_version' => (
	required => 1,
	is       => 'ro',
	isa      => 'Str'
);

has 'processor' => (
	required => 1,
	is       => 'ro',
	isa      => 'HashRef[Value]'
);

has 'memory' => (
	required => 1,
	is       => 'ro',
	isa      => 'HashRef[Int]'
);

has 'disks' => (
	required => 0,
	is       => 'ro',
	isa      => 'HashRef[HashRef[Value]]'
);

has 'temp' => (
	required => 0,
	is       => 'ro',
	isa      => 'HashRef[Int]'
);

# Only key in hash is currently 'serial'
has 'relay' => (
	required => 0,
	is       => 'ro',
	isa      => 'HashRef[Str]'
);

has 'uptime_since' => (
	required => 0,
	is       => 'ro',
	isa      => 'Str'
);

# Store auxillary data in the report. This is data that might be used later.
has 'aux' => (
	required => 0,
	is       => 'rw',
	isa      => 'HashRef[Any]'
);

__PACKAGE__->meta->make_immutable;


__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

