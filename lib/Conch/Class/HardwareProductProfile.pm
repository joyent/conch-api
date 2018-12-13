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

=head2 sas_hdd_num

=head2 sas_hdd_size

=head2 sas_hdd_slots

=head2 sas_ssd_num

=head2 sas_ssd_size

=head2 sas_ssd_slots

=head2 sata_hdd_num

=head2 sata_hdd_size

=head2 sata_hdd_slots

=head2 sata_ssd_num

=head2 sata_ssd_size

=head2 sata_ssd_slots

=head2 nvme_ssd_num

=head2 nvme_ssd_size

=head2 nvme_ssd_slots

=head2 raid_lun_num

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
		sas_hdd_num
		sas_hdd_size
		sas_hdd_slots
		sas_ssd_num
		sas_ssd_size
		sas_ssd_slots
		sata_hdd_num
		sata_hdd_size
		sata_hdd_slots
		sata_ssd_num
		sata_ssd_size
		sata_ssd_slots
		nvme_ssd_num
		nvme_ssd_size
		nvme_ssd_slots
		raid_lun_num
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
