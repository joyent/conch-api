package Conch::Class::Role::JsonV1;
use Mojo::Base -role, -signatures;

use Data::Printer;

sub as_v1_json {
  my $self   = shift;
  my %fields = %$self;
  return {%fields};
}

1;
