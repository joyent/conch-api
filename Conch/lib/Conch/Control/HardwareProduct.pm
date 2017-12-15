package Conch::Control::HardwareProduct;

use strict;
use warnings;
use Log::Any '$log';

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( list_hardware_products get_hardware_product );

sub list_hardware_products {
  my ($schema) = @_;

  my @hardware_products = $schema->resultset('HardwareProduct')->search(
    {
      'me.deactivated'              => { '=',  undef },
      'hardware_product_profile.id' => { '!=', undef }
    },
    { prefetch => [ { hardware_product_profile => 'zpool' }, 'vendor' ] }
  )->all;

  my @hw_response = map { build_hardware_product_hash($_) } @hardware_products;
  return @hw_response;
}

sub get_hardware_product {
  my ( $schema, $hw_id ) = @_;

  my $hardware_product = $schema->resultset('HardwareProduct')->search(
    {
      'me.id'                       => $hw_id,
      'me.deactivated'              => { '=', undef },
      'hardware_product_profile.id' => { '!=', undef }
    },
    { prefetch => [ { hardware_product_profile => 'zpool' }, 'vendor' ] }
  )->single;

  return build_hardware_product_hash($hardware_product)
    if defined($hardware_product);
}

# Build a hash with hardware product and hardware product profile details.
# Includes zpool info if available. Expects hardware_product_profile to exist
sub build_hardware_product_hash {
  my ($hw) = shift;

  my $hw_profile = $hw->hardware_product_profile;

  my $hw_vendor_name = $hw->vendor->name;

  my %hw_columns = $hw->get_columns;

  my %profile_columns = $hw_profile->get_columns;

  my %res = %hw_columns{qw/id name alias prefix /};
  $res{vendor} = $hw_vendor_name;

  my %profile = %profile_columns{
    qw/purpose bios_firmware hba_firmware
      cpu_num cpu_type dimms_num ram_total nics_num sata_num sata_size sata_slots
      sas_num sas_size sas_slots ssd_num ssd_size ssd_slots psu_total/
  };
  $res{profile} = \%profile;

  my $zpool_profile = $hw_profile->zpool;
  if ( defined($zpool_profile) ) {
    my %zpool_columns = $zpool_profile->get_columns;
    my %zpool = %zpool_columns{qw/vdev_t vdev_n disks_per spare log cache/};
    $res{profile}{zpool} = \%zpool;
  }
  else {
    $res{profile}{zpool} = undef;
  }
  return \%res;
}

1;
