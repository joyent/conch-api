package Conch::Data::Report::Server;

use Moose;
use MooseX::Constructor::AllErrors;
use MooseX::Types::UUID qw( UUID );
use MooseX::Storage;
use Conch::Role::Report;

use Conch::Control::Device::Configuration;
use Conch::Control::Device::Environment;
use Conch::Control::Device::Inventory;
use Conch::Control::Device::Network;

with Storage('format' => 'JSON');

with 'Conch::Role::Report';

sub validations {
  my $self = shift;
  my @validations = (
    \&validate_cpu_temp,
    \&validate_product,
    \&validate_system,
    \&validate_nics_num,
    $self->disks ? \&validate_disk_temp : (),
    $self->disks ? \&validate_disks : (),
    $self->interfaces ? \&validate_links : (),
    $self->interfaces ? \&validate_wiremap : (),
  );
  return @validations;
}

sub nics_count {
  my $self = shift;
  return scalar (keys %{$self->interfaces});
}

has 'product_name' => (
  required => 1,
  is => 'ro',
  isa => 'Str'
);

has 'serial_number' => (
  required => 1,
  is => 'ro',
  isa => 'Str'
);

has 'system_uuid' => (
  required => 1,
  is => 'ro',
  isa => UUID
);

has 'state' => (
  required => 1,
  is => 'ro',
  isa => 'Str'
);

has 'interfaces' => (
  required => 0,
  is => 'ro',
  # hash can contain undef values
  isa => 'HashRef[HashRef[Maybe[Str]]]'
);

has 'bios_version' => (
  required => 1,
  is => 'ro',
  isa => 'Str'
);

has 'processor' => (
  required => 1,
  is => 'ro',
  isa => 'HashRef[Value]'
);

has 'memory' => (
  required => 1,
  is => 'ro',
  isa => 'HashRef[Int]'
);

has 'disks' => (
  required => 0,
  is => 'ro',
  isa => 'HashRef[HashRef[Value]]'
);

has 'temp' => (
  required => 0,
  is => 'ro',
  isa => 'HashRef[Int]'
);

# Only key in hash is currently 'serial'
has 'relay' => (
  required => 0,
  is => 'ro',
  isa => 'HashRef[Str]'
);

has 'uptime_since' => (
  required => 0,
  is => 'ro',
  isa => 'Str'
);

# Store auxillary data in the report. This is data that might be used later.
has 'aux' => (
  required => 0,
  is => 'rw',
  isa => 'HashRef[Any]'
);

__PACKAGE__->meta->make_immutable;

