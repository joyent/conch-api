package Conch::Controller::User;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;

sub set_settings ($c) {
  my $body = $c->req->json;
  return $c->status(400, { error => 'Payload required' })
    unless $body;
  $c->user_settings->set_settings($c->stash('user_id'), $body);
  $c->status(200);
}

sub set_setting ($c) {
  my $body = $c->req->json;
  my $setting_key = $c->param('key');
  my $setting_value = $body->{$setting_key};
  return $c->status(400, { error =>
      "Setting key in request object must match name in the URL ('$setting_key')"
    }) unless $setting_value;
  $c->user_settings->set_settings(
    $c->stash('user_id'),
    { $setting_key => $setting_value }
  );
  $c->status(200);
}

sub get_settings ($c) {
  my $settings = $c->user_settings->get_settings($c->stash('user_id'));
  $c->status(200, $settings );
}

sub get_setting ($c) {
  my $setting_key = $c->param('key');
  my $settings = $c->user_settings->get_settings($c->stash('user_id'));
  return $c->status(404, { error => "No such setting '$setting_key'" })
    unless $settings->{$setting_key};
  $c->status(200, $settings->{$setting_key});
}

sub delete_setting ($c) {
  my $setting_key = $c->param('key');
  unless ($c->user_settings->delete_user_setting($c->stash('user_id'), $setting_key)) {
    return $c->status(404, { error => "No such setting '$setting_key'" } );
  } else {
    return $c->status(204);
  }
}

1;
