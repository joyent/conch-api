=pod

=head1 NAME

Conch::Model::DeviceLocation

=head1 METHODS

=cut
package Conch::Model::DeviceLocation;
use Mojo::Base -base, -signatures;

use Conch::Class::DatacenterRack;
use Conch::Class::DatacenterRoom;
use Conch::Class::DeviceLocation;
use Conch::Class::HardwareProduct;
use Conch::Pg;

=head2 lookup

Find a DeviceLocation by Device ID or return undef.

=cut
sub lookup ( $self, $device_id ) {
	my $ret = Conch::Pg->new->db->query(
		q{
    SELECT
      loc.rack_unit_start AS location_rack_unit_start,

      rack.id           AS rack_id,
      rack.name         AS rack_name,
      rack_role.name    AS rack_role_name,
      ARRAY(SELECT rack_unit_start FROM datacenter_rack_layout
         WHERE rack_id = rack.id
         ORDER BY rack_unit_start)
                        AS rack_slots,

      room.id           AS room_id,
      room.az           AS room_az,
      room.alias        AS room_alias,
      room.vendor_name  AS room_vendor_name,

      hw_product.id     AS hw_product_id,
      hw_product.name   AS hw_product_name,
      hw_product.alias  AS hw_product_alias,
      hw_product.prefix AS hw_product_prefix,
      hw_product.hardware_vendor_id AS hw_product_vendor,

      hw_product.specification       AS hw_product_specification,
      hw_product.sku                 AS hw_sku,
      hw_product.generation_name     AS hw_generation_name,
      hw_product.legacy_product_name AS hw_legacy_product_name

    FROM device_location loc
    JOIN datacenter_rack rack
      ON loc.rack_id = rack.id

    JOIN datacenter_rack_role rack_role
      ON rack.datacenter_rack_role_id = rack_role.id

    JOIN datacenter_room room
      ON rack.datacenter_room_id = room.id

    JOIN datacenter_rack_layout layout
      ON layout.rack_id = rack.id AND layout.rack_unit_start = loc.rack_unit_start

    JOIN hardware_product hw_product
      ON layout.hardware_product_id = hw_product.id

    JOIN hardware_vendor vendor
      ON hw_product.hardware_vendor_id = vendor.id

    WHERE loc.device_id = ?
  }, $device_id
	)->hash;
	return undef unless $ret;
	return _build_device_location($ret);
}

sub _build_device_location ($loc) {
	my $datacenter_rack = Conch::Class::DatacenterRack->new(
		id        => $loc->{rack_id},
		name      => $loc->{rack_name},
		role_name => $loc->{rack_role_name},
		slots     => $loc->{rack_slots},
	);
	my $datacenter_room = Conch::Class::DatacenterRoom->new(
		id          => $loc->{room_id},
		az          => $loc->{room_az},
		alias       => $loc->{room_alias},
		vendor_name => $loc->{room_vendor_name},
	);
	my $hardware_product = Conch::Class::HardwareProduct->new(
		id                  => $loc->{hw_product_id},
		name                => $loc->{hw_product_name},
		alias               => $loc->{hw_product_alias},
		prefix              => $loc->{hw_product_prefix},
		vendor              => $loc->{hw_product_vendor},
		specification       => $loc->{hw_product_specification},
		sku                 => $loc->{hw_sku},
		generation_name     => $loc->{hw_generation_name},
		legacy_product_name => $loc->{legacy_product_name},
	);
	return Conch::Class::DeviceLocation->new(
		rack_unit               => $loc->{location_rack_unit_start},
		datacenter_rack         => $datacenter_rack,
		datacenter_room         => $datacenter_room,
		target_hardware_product => $hardware_product
	);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
