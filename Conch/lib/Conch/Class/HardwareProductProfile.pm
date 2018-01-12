package Conch::Class::HardwareProductProfile;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV2';

has [qw(
  bios_firmware
  cpu_num
  cpu_type
  dimms_num
  hba_firmware
  nics_num
  psu_total
  purpose
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
  )];

sub as_v2_json {
  my $self = shift;
  {
    bios_firmware => $self->bios_firmware,
    cpu_num => $self->cpu_num,
    cpu_type => $self->cpu_type,
    dimms_num => $self->dimms_num,
    hba_firmware => $self->hba_firmware,
    nics_num => $self->nics_num,
    psu_total => $self->psu_total,
    purpose => $self->purpose,
    ram_total => $self->ram_total,
    sas_num => $self->sas_num,
    sas_size => $self->sas_size,
    sas_slots => $self->sas_slots,
    sata_num => $self->sata_num,
    sata_size => $self->sata_size,
    sata_slots => $self->sata_slots,
    ssd_num => $self->ssd_num,
    ssd_size => $self->ssd_size,
    ssd_slots => $self->ssd_slots,
    usb_num => $self->usb_num,
    zpool => $self->zpool->as_v2_json
  }
}
1;
