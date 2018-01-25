package Conch::Controller::HardwareProduct;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';

use Data::Printer;

sub list ($c) {
	my $hardware_products = $c->hardware_product->list;
	$c->status( 200, [ map { $_->as_v1_json } @$hardware_products ] );
}

sub get ($c) {
	my $hw_id = $c->param('id');
	return $c->status( 400,
		{ error => "Hardware Product ID must be a UUID. Got '$hw_id'." } )
		unless is_uuid($hw_id);
	my $hw_attempt = $c->hardware_product->lookup($hw_id);
  if($hw_attempt) {
    return $c->status( 200, $hw_attempt->as_v1_json );
  } else {
    return $c->status( 404, { error => "Hardware Product $hw_id not found" } );
  }
}

1;
