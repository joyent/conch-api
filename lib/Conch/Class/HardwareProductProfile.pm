=pod

=head1 NAME

Conch::Class::HardwareProductProfile

=head1 METHODS

=cut

package Conch::Class::HardwareProductProfile;
use Mojo::Base -base, -signatures;

=head2 id

=head2 bios_firmware

=head2 cpu_num

=head2 cpu_type

=head2 dimms_num

=head2 hba_firmware

=head2 nics_num

=head2 psu_total

=head2 purpose

=head2 rack_unit

=head2 ram_total

=head2 sas_num

=head2 sas_size

=head2 sas_slots

=head2 sata_num

=head2 sata_size

=head2 sata_slots

=head2 ssd_num

=head2 ssd_size

=head2 ssd_slots

=head2 usb_num

=head2 zpool

=cut

has [
	qw(
		id
		bios_firmware
		cpu_num
		cpu_type
		dimms_num
		hba_firmware
		nics_num
		psu_total
		purpose
		rack_unit
		ram_total
		sas_num
		sas_size
		sas_slots
		sata_num
		sata_size
		sata_slots
		ssd_num
		ssd_size
		ssd_slots
		usb_num
		zpool
		)
];

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
