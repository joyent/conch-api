package Conch::Route::HardwareProduct;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::REST;
use Hash::MultiValue;

use Conch::Control::HardwareProduct;

use Data::Printer;
use Data::Validate::UUID 'is_uuid';

set serializer => 'JSON';


get '/hardware_product' => needs login => sub {
  my @hardware_products = list_hardware_products(schema);
  status_200(\@hardware_products);
};

get '/hardware_product/:id' => needs login => sub {
  my $hw_id     = param 'id';
  return status_400("Hardware Product ID in path must be a UUID") unless is_uuid($hw_id);

  my $hardware_product = get_hardware_product(schema, $hw_id);

  return status_404("Hardware Product '$hw_id' not found") unless $hardware_product;

  status_200($hardware_product);
};


1;
