# Regular expressions matches
package Conch::Role::DeviceValidation;

use strict;
use Moose::Role;

requires qw( _validate );

has 'report_id' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

has 'device' => (
  is       => 'ro',
  isa      => 'Ref',
  required => 1
);

has 'device_id' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_device_id'
);

has '_status' => (
  is      => 'rw',
  isa     => 'Int',
  default => sub { 1 }
);

sub _device_id {
  my ($self) = @_;
  return $self->device->id;
}

sub valid {
  my ( $self, $msg, $has_wants ) = @_;
}

sub invalid {
  my ( $self, $msg, $has_wants ) = @_;
  $self->_status(0);
}

sub validate {
  my ( $self, $criteria ) = @_;
  $self->_validate($criteria);
  return $self->_status;
}

1;

#
