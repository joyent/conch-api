package Conch::Class::DatacenterRack;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [qw( id name role_name datacenter_room_id )];

sub as_v1_json {
  my $self = shift;
  {
    id        => $self->id,
    name      => $self->name,
    role_name => $self->role_name
  };
}

1;

