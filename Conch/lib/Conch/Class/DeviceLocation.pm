package Conch::Class::DeviceLocation;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [
  qw(
    rack_unit
    datacenter_rack
    datacenter_room
    target_hardware_product
    )
];

sub as_v1_json {
  my $self = shift;
  return {
    datacenter => {
      id          => $self->datacenter_room->id,
      name        => $self->datacenter_room->az,
      vendor_name => $self->datacenter_room->vendor_name,
    },
    rack => {
      id   => $self->datacenter_rack->id,
      unit => $self->rack_unit,
      name => $self->datacenter_rack->name,
      role => $self->datacenter_rack->role_name,
    },
    target_hardware_product => {
      id     => $self->target_hardware_product->id,
      name   => $self->target_hardware_product->name,
      alias  => $self->target_hardware_product->alias,
      vendor => $self->target_hardware_product->vendor,
    },
  };
}

1;
