package Mojo::Conch::Class::HardwareProduct;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Mojo::Conch::Class::Role::JsonV2';

has [qw(
  id
  name
  alias
  prefix
  vendor
  profile
  )];

sub as_v2_json {
  my $self = shift;
  {
    id => $self->id,
    name => $self->name,
    alias => $self->alias,
    prefix => $self->prefix,
    vendor => $self->vendor,
    profile => $self->profile && $self->profile->as_v2_json
  }
}

1;
