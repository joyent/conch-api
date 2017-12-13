package Mojo::Conch::Controller::DeviceSettings;

use Mojo::Base 'Mojolicious::Controller', -signatures;


sub set_all ($c) {
  my $body = $c->req->json;
  return $c->status(400, { error => 'Payload required' })
    unless $body;
  $c->device_settings->set_settings($c->stash('current_device')->id, $body);
  $c->status(200);
}

sub set_single ($c) {
  my $body = $c->req->json;
  my $setting_key = $c->param('key');
  my $setting_value = $body->{$setting_key};
  return $c->status(400, { error =>
      "Setting key in request object must match name in the URL ('$setting_key')"
    }) unless $setting_value;
  $c->device_settings->set_settings(
    $c->stash('current_device')->id,
    { $setting_key => $setting_value }
  );
  $c->status(200);
}

sub get_all ($c) {
  my $settings = $c->device_settings->get_settings($c->stash('current_device')->id);
  $c->status(200, $settings );
}

sub get_single ($c) {
  my $setting_key = $c->param('key');
  my $settings = $c->device_settings->get_settings($c->stash('current_device')->id);
  return $c->status(404)
    unless $settings->{$setting_key};
  $c->status(200, $settings->{$setting_key});
}

sub delete_single ($c) {
  my $setting_key = $c->param('key');
  unless ($c->device_settings->delete_device_setting($c->stash('current_device')->id, $setting_key)) {
    return $c->status(404, { error => "No such setting '$setting_key'" } );
  } else {
    return $c->status(204);
  }
}

1;
