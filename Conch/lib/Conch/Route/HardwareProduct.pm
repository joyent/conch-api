package Conch::Route::HardwareProduct;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw(
	hardware_product_routes
);

sub hardware_product_routes {
	my $r = shift;

	$r->get('/hardware_product')->to('hardware_product#list');
	$r->get('/hardware_product/:id')->to('hardware_product#get');

}

1;
