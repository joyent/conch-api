package Conch::Controller::Device;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';

use aliased 'Conch::Class::DeviceDetailed';

use Data::Printer;

sub under ($c) {
  my $device_id = $c->param('id');
  my $maybe_device =
    $c->device->lookup_for_user( $c->stash('user_id'), $device_id );
  if ( $maybe_device->is_fail ) {
    $c->status( 404, { error => "Device '$device_id' not found" } );
    return 0;
  }
  $c->stash( current_device => $maybe_device->value );
  return 1;
}

sub get ($c) {
  return unless $c->under;
  my $device = $c->stash('current_device');

  my $device_report = $c->device_report->latest_device_report( $device->id );
  my $report        = {};
  my $validations   = [];
  if ( $device_report->is_success ) {
    $validations =
      $c->device_report->validation_results( $device_report->value->{id} );
    $report = $device_report->value->{report};
    delete $report->{'__CLASS__'};
  }

  my $maybe_location = $c->device_location->lookup( $device->id );
  my $nics           = $c->device->device_nic_neighbors( $device->id );

  my $detailed_device = DeviceDetailed->new(
    device             => $device,
    latest_report      => $report,
    validation_results => $validations,
    nics               => $nics,
    location           => $maybe_location->value
  );

  $c->status( 200, $detailed_device->as_v1_json );
}

sub graduate($c) {
  my $device    = $c->stash('current_device');
  my $device_id = $device->id;
  return $c->status( 409, "Device $device_id has already been graduated" )
    if defined( $device->graduated );

  $c->device->graduate_device( $device->id );

  $c->status(303);
  $c->redirect_to( $c->url_for("/device/$device_id")->to_abs );
}

sub set_triton_reboot ($c) {
  my $device = $c->stash('current_device');
  $c->device->set_triton_reboot( $device->id );

  $c->status(303);
  $c->redirect_to( $c->url_for( '/device/' . $device->id )->to_abs );
}

sub set_triton_uuid ($c) {
  my $device = $c->stash('current_device');
  my $triton_uuid = $c->req->json && $c->req->json->{triton_uuid};
  return $c->status(
    400,
    {
      error =>
        "'triton_uuid' attribute must be present in JSON object and a UUID"
    }
  ) unless defined($triton_uuid) && is_uuid($triton_uuid);

  $c->device->set_triton_uuid( $device->id, $triton_uuid );

  $c->status(303);
  $c->redirect_to( $c->url_for( '/device/' . $device->id )->to_abs );
}

sub set_triton_setup ($c) {
  my $device    = $c->stash('current_device');
  my $device_id = $device->id;
  return $c->status(
    409,
    {
      error =>
"Device $device_id must be marked as rebooted into Triton and the Trition "
        . "UUID set before it can be marked as set up for Triton"
    }
    )
    unless ( defined( $device->latest_triton_reboot )
    && defined( $device->triton_uuid ) );

  return $c->status( 409,
    "Device $device_id has already been marked as set up for Triton" )
    if defined( $device->triton_setup );

  $c->device->set_triton_setup( $device->id );

  $c->status(303);
  $c->redirect_to( $c->url_for("/device/$device_id")->to_abs );
}

sub set_asset_tag ($c) {
  my $device = $c->stash('current_device');
  my $asset_tag = $c->req->json && $c->req->json->{asset_tag};
  return $c->status(
    400,
    {
      error =>
"'asset_tag' attribute must be present and in JSON object a string value"
    }
  ) unless defined($asset_tag) && ref($asset_tag) eq '';

  $c->device->set_asset_tag( $device->id, $asset_tag );

  $c->status(303);
  $c->redirect_to( $c->url_for( '/device/' . $device->id )->to_abs );
}

1;
