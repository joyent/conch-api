package Conch::Data::DeviceLog;

use Moose;
use MooseX::Constructor::AllErrors;
use MooseX::Types::UUID qw( UUID );
use MooseX::Storage;

with Storage( 'format' => 'JSON' );

has 'component_type' => (
  required => 1,
  is       => 'ro',
  isa      => 'Str'
);

has 'component_id' => (
  required => 0,
  is       => 'ro',
  isa      => UUID
);

has 'msg' => (
  required => 1,
  is       => 'ro',
  isa      => 'Str'
);

__PACKAGE__->meta->make_immutable;

