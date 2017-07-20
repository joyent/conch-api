package Conch::Control::Device::Configuration;

use strict;
use Log::Report;

use Exporter 'import';
our @EXPORT = qw( validate_product );


sub validate_product {
  my ($schema, $device, $report_id) = @_;

  $device or fault "device undefined";

  my $device_id = $device->id;

  trace("$device_id: report $report_id: Validating hardware product information");

  my $product_name = $device->hardware_product->name;
  my $product_name_log = "Has = $product_name, Want = Matches:Joyent";
  my $product_name_status;

  if ( $product_name !~ /Joyent/ ) {
    $product_name_status = 0;
    warning ("$device_id: CRITICAL: Product name not set: $product_name_log");
  } else {
    $product_name_status = 1;
    trace("$device_id: OK: Product name set: $product_name_log");
  }

  $schema->resultset('DeviceValidate')->update_or_create({
    device_id       => $device_id,
    report_id       => $report_id,
    component_type  => "BIOS",
    component_name  => "product_name",
    log             => $product_name_log,
    status          => $product_name_status
  });
}

1;
