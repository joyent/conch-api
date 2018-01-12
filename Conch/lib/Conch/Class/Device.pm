package Conch::Class::Device;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [qw(
  id
  asset_tag
  boot_phase
  created
  hardware_product
  health
  graduated
  last_seen
  latest_triton_reboot
  role
  state
  system_uuid
  triton_uuid
  triton_setup
  updated
  uptime_since
  validated
  )];

1;
