package Conch::Class::ZpoolProfile;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [
  qw(
    name
    cache
    log
    disk_per
    spare
    vdev_n
    vdev_t
    )
];

1;
