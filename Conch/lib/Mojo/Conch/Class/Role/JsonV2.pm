package Mojo::Conch::Class::Role::JsonV2;
use Mojo::Base -role, -signatures;

use Data::Printer;

sub as_v2_json {
  my $self = shift;
  my %fields = %$self;
  return {%fields};
}

1;
