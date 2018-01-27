=pod

=head1 NAME

Conch::Legacy::Control::Device::Configuration - B<LEGACY MODULE>

=head1 METHODS

=cut
package Conch::Legacy::Control::Device::Configuration;

use strict;
use Log::Report;
use Mojo::JSON qw(decode_json encode_json);

use Exporter 'import';
our @EXPORT = qw( validate_product );

=head2 validate_product

Validate device product name.

=cut
sub validate_product {
	my ( $schema, $device, $report_id ) = @_;

	$device or fault "device undefined";

	my $device_id = $device->id;

	trace(
		"$device_id: report $report_id: Validating hardware product information");

	my $product_name     = $device->hardware_product->name;
	my $product_name_log = "Has = $product_name, Want = Matches:Joyent";
	my $product_name_status;

	if ( $product_name !~ /Joyent/ ) {
		$product_name_status = 0;
		mistake("$device_id: CRITICAL: Product name not set: $product_name_log");
	}
	else {
		$product_name_status = 1;
		trace("$device_id: OK: Product name set: $product_name_log");
	}

	$schema->resultset('DeviceValidate')->create(
		{
			device_id  => $device_id,
			report_id  => $report_id,
			validation => encode_json(
				{
					component_type => "BIOS",
					component_name => "product_name",
					log            => $product_name_log,
					status         => $product_name_status
				}
			)
		}
	);
}

1;


__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

