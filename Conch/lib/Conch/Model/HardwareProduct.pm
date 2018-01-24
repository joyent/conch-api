package Conch::Model::HardwareProduct;
use Mojo::Base -base, -signatures;

use Attempt qw(try fail success attempt when_defined);

use aliased 'Conch::Class::HardwareProduct';
use aliased 'Conch::Class::HardwareProductProfile';
use aliased 'Conch::Class::ZpoolProfile';

has 'pg';

# Query fields used to build HardwareProduct, which depends on
# HardwareProductProfile and ZpoolProfile
my $fields = q{
  hw_product.id AS hw_product_id,
  hw_product.name AS hw_product_name,
  hw_product.alias AS hw_product_alias,
  hw_product.prefix AS hw_product_prefix,
  vendor.name AS hw_product_vendor,

  hw_profile.bios_firmware AS hw_profile_bios_profile,
  hw_profile.cpu_num AS hw_profile_cpu_num,
  hw_profile.cpu_type AS hw_profile_cpu_type,
  hw_profile.dimms_num AS hw_profile_dimms_num,
  hw_profile.hba_firmware AS hw_profile_hba_firmware,
  hw_profile.nics_num AS hw_profile_nics_num,
  hw_profile.psu_total AS hw_profile_psu_total,
  hw_profile.purpose AS hw_profile_purpose,
  hw_profile.ram_total AS hw_profile_ram_total,
  hw_profile.sas_num AS hw_profile_sas_num,
  hw_profile.sas_size AS hw_profile_sas_size,
  hw_profile.sas_slots AS hw_profile_sas_slots,
  hw_profile.sata_num AS hw_profile_sata_num,
  hw_profile.sata_size AS hw_profile_sata_size,
  hw_profile.sata_slots AS hw_profile_sata_slots,
  hw_profile.ssd_num AS hw_profile_ssd_num,
  hw_profile.ssd_size AS hw_profile_ssd_size,
  hw_profile.ssd_slots AS hw_profile_ssd_slots,
  hw_profile.usb_num AS hw_profile_usb_num,

  zpool.id AS zpool_id,
  zpool.name AS zpool_name,
  zpool.cache AS zpool_cache,
  zpool.log AS zpool_log,
  zpool.disk_per AS zpool_disk_per,
  zpool.spare AS zpool_spare,
  zpool.vdev_n AS zpool_vdev_n,
  zpool.vdev_t AS zpool_vdev_t
};

sub list ($self) {
  my $hw_product_hashes = $self->pg->db->query(
    qq{
      SELECT $fields
      FROM hardware_product hw_product
      JOIN hardware_product_profile hw_profile
        ON hw_product.id = hw_profile.product_id
      JOIN hardware_vendor vendor
        ON hw_product.vendor = vendor.id
      LEFT JOIN zpool_profile zpool
        ON hw_profile.zpool_id = zpool.id
      WHERE hw_product.deactivated IS NULL
    }
  )->hashes->to_array;
  return [ map { _build_hardware_product($_) } @$hw_product_hashes ];
}

sub lookup ( $self, $hw_id ) {
  when_defined { _build_hardware_product(shift) }
  $self->pg->db->query(
    qq{
        SELECT $fields
        FROM hardware_product hw_product
        JOIN hardware_product_profile hw_profile
          ON hw_product.id = hw_profile.product_id
        JOIN hardware_vendor vendor
          ON hw_product.vendor = vendor.id
        LEFT JOIN zpool_profile zpool
          ON hw_profile.zpool_id = zpool.id
        WHERE hw_product.deactivated IS NULL
          AND hw_product.id = ?
      }, $hw_id
  )->hash;
}

sub _build_hardware_product ($hw) {

  my $zpool_profile = $hw->{zpool_id}
    ? ZpoolProfile->new(
        name     => $hw->{zpool_name},
        cache    => $hw->{zpool_cache},
        log      => $hw->{zpool_log},
        disk_per => $hw->{zpool_disk_per},
        spare    => $hw->{zpool_spare},
        vdev_n   => $hw->{zpool_vdev_n},
        vdev_t   => $hw->{zpool_vdev_t}
	)
    : undef;
  my $hw_profile = HardwareProductProfile->new(
    bios_firmware => $hw->{hw_profile_bios_firmware},
    cpu_num       => $hw->{hw_profile_cpu_num},
    cpu_type      => $hw->{hw_profile_cpu_type},
    dimms_num     => $hw->{hw_profile_dimms_num},
    hba_firmware  => $hw->{hw_profile_hba_firmware},
    nics_num      => $hw->{hw_profile_nics_num},
    psu_total     => $hw->{hw_profile_psu_total},
    purpose       => $hw->{hw_profile_purpose},
    ram_total     => $hw->{hw_profile_ram_total},
    sas_num       => $hw->{hw_profile_sas_num},
    sas_size      => $hw->{hw_profile_sas_size},
    sas_slots     => $hw->{hw_profile_sas_slots},
    sata_num      => $hw->{hw_profile_sata_num},
    sata_size     => $hw->{hw_profile_sata_size},
    sata_slots    => $hw->{hw_profile_sata_slots},
    ssd_num       => $hw->{hw_profile_ssd_num},
    ssd_size      => $hw->{hw_profile_ssd_size},
    ssd_slots     => $hw->{hw_profile_ssd_slots},
    usb_numb      => $hw->{hw_profile_usb_num},
    zpool         => $zpool_profile
  );

  return HardwareProduct->new(
    id      => $hw->{hw_product_id},
    name    => $hw->{hw_product_name},
    alias   => $hw->{hw_product_alias},
    prefix  => $hw->{hw_product_prefix},
    vendor  => $hw->{hw_product_vendor},
    profile => $hw_profile
  );
}

1;
