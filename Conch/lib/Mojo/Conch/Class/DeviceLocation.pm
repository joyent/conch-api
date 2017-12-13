package Mojo::Conch::Class::DeviceLocation;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Mojo::Conch::Class::Role::JsonV2';

has [qw(
  rack_unit
  datacenter_rack
  datacenter_room
  target_hardware_product
  )];

sub as_v2_json {
  my $self = shift;

  my $target_hardware_product ||= $self->target_hardware_product->as_v2_json;
  delete $target_hardware_product->{profile};

  my $rack = $self->datacenter_rack->as_v2_json;
  $rack->{rack_unit} = $self->rack_unit;

  return {
    rack => $rack,
    datacenter => $self->datacenter_room->as_v2_json,
    target_hardware_product => $target_hardware_product
  };

}

1;
