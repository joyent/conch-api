package Mojo::Conch::Class::DatacenterRack;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Mojo::Conch::Class::Role::JsonV2';

has [qw( id name role_name datacenter_room_id )];

sub as_v2_json {
  my $self = shift;
  {
    id => $self->id,
    name => $self->az,
    role_name => $self->alias
  };
}

1;


