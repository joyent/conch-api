package Conch::Data::DeviceReport;

use Moose;
use MooseX::Constructor::AllErrors;
use MooseX::Types::UUID qw( UUID );
use MooseX::Storage;

with Storage('format' => 'JSON');

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
  required => 1,
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
  required => 1,
  is => 'ro',
  isa => 'HashRef[HashRef[Value]]'
);

has 'temp' => (
  required => 1,
  is => 'ro',
  isa => 'HashRef[Int]'
);

# Only key in hash is currently 'serial'
has 'relay' => (
  required => 0,
  is => 'ro',
  isa => 'HashRef[Str]'
);

__PACKAGE__->meta->make_immutable;
