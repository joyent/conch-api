package Mojo::Conch::Controller::HardwareProduct;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';

use Data::Printer;


sub list ($c) {
  my $hardware_products = $c->hardware_product->list;
  $c->status(200, [ map { $_->as_v2_json } @$hardware_products ]);
}

sub get ($c) {
  my $hw_id = $c->param('id');
  my $hw_attempt = $c->hardware_product->lookup($hw_id);

  return $c->status(404, { error => "Hardware Product $hw_id not found" })
    if $hw_attempt->is_fail;
  $c->status(200, $hw_attempt->value->as_v2_json);
}

1;
