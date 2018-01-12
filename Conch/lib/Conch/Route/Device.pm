package Conch::Route::Device;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw(
  device_routes
);

sub device_routes {
  my $r = shift;

  $r->get('/device/:id')->to('device#get');

  # routes namespaced for a specific device
  my $with_device = $r->under('/device/:id')->to('device#under');

  $r->post('/device/:id')->to('device_report#process');

  $with_device->post('/graduate')->to('device#graduate');
  $with_device->post('/triton_setup')->to('device#set_triton_setup');
  $with_device->post('/triton_uuid')->to('device#set_triton_uuid');
  $with_device->post('/triton_reboot')->to('device#set_triton_reboot');
  $with_device->post('/asset_tag')->to('device#set_asset_tag');

  $with_device->get('/location')->to('device_location#get');
  $with_device->post('/location')->to('device_location#set');
  $with_device->delete('/location')->to('device_location#delete');

  $with_device->get('/settings')->to('device_settings#get_all');
  $with_device->post('/settings')->to('device_settings#set_all');

  $with_device->get('/settings/:key')->to('device_settings#get_single');
  $with_device->post('/settings/:key')->to('device_settings#set_single');

  $with_device->delete('/settings/:key')->to('device_settings#delete_single');

}

1;
