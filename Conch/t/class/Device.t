use Mojo::Base -strict;
use Test::More;

use Conch::Class::Device;
use Data::Printer;

new_ok('Conch::Class::Device');

my $attrs = {
  id => 'id',
  asset_tag => 'asset_tag',
  boot_phase => 'boot_phase',
  created => 'created',
  hardware_product => 'hardware_product',
  health => 'health',
  graduated => 'graduated',
  last_seen => 'last_seen',
  latest_triton_reboot => 'latest_triton_reboot',
  role => 'role',
  state => 'state',
  system_uuid => 'system_uuid',
  triton_uuid => 'triton_uuid',
  updated => 'updated',
  uptime_since => 'uptime_since',
  validated => 'validated'
  };

my $device = Conch::Class::Device->new({
    %$attrs, encode_json => sub { shift }
  });


can_ok($device, 'id');
can_ok($device, 'asset_tag');
can_ok($device, 'boot_phase');
can_ok($device, 'created');
can_ok($device, 'hardware_product');
can_ok($device, 'health');
can_ok($device, 'graduated');
can_ok($device, 'last_seen');
can_ok($device, 'latest_triton_reboot');
can_ok($device, 'role');
can_ok($device, 'state');
can_ok($device, 'system_uuid');
can_ok($device, 'triton_uuid');
can_ok($device, 'triton_setup');
can_ok($device, 'updated');
can_ok($device, 'uptime_since');
can_ok($device, 'validated');

can_ok($device, 'as_v1_json');
done_testing();


