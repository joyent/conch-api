package Conch::Role::Validation;

use Moose;

has 'validation_errors' => (
  is      => 'rw',
  traits  => ['Array'],
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
  handles => {
    validation_error => 'push'
  }
);

__PACKAGE__->meta->make_immutable;
