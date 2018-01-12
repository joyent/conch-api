package Conch::Class::DatacenterRoom;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [qw( id az alias vendor_name )];

sub as_v1_json {
  my $self = shift;
  {
    id => $self->id,
    az => $self->az,
    alias => $self->alias,
    vendor_name => $self->vendor_name
  };
}

1;


