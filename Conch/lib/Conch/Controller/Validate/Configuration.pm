package Conch::Controller::Validate::Configuration;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Conch::Controller::Validate::Configuration - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  $c->response->body('Matched Conch::Controller::Validate::Configuration in Validate::Configuration.');

  $c->forward('product');
}

sub product : Private {
  my ( $self, $c ) = @_;

  # Validate that req->{data}->{product_name} is being passed up
  my $device_id = $c->req->data->{serial_number};
  $c->log->debug("$device_id: Validating hardware product information");

  my $product_name = $c->req->data->{product_name};
  my $product_name_log = "Has = $product_name, Want = Matches:Joyent";
  my $product_name_status;

  if ( $product_name !~ /Joyent/ ) {
    $product_name_status = 0;
    $c->log->debug("$device_id: CRITICAL: Product name not set: $product_name_log");
  } else {
    $product_name_status = 1;
    $c->log->debug("$device_id: OK: Product name set: $product_name_log");
  }

  my $product_name_record = $c->model('DB::DeviceValidate')->update_or_create({
    device_id       => $device_id,
    component_type  => "BIOS",
    component_name  => "product_name",
    log             => $product_name_log,
    status          => $product_name_status
  });
}



=encoding utf8

=head1 AUTHOR

Super-User

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
