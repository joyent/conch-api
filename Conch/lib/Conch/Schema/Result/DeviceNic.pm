use utf8;
package Conch::Schema::Result::DeviceNic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::DeviceNic

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<device_nic>

=cut

__PACKAGE__->table("device_nic");

=head1 ACCESSORS

=head2 mac

  data_type: 'macaddr'
  is_nullable: 0

=head2 device_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 iface_name

  data_type: 'text'
  is_nullable: 0

=head2 iface_type

  data_type: 'text'
  is_nullable: 0

=head2 iface_vendor

  data_type: 'text'
  is_nullable: 0

=head2 iface_driver

  data_type: 'text'
  is_nullable: 1

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 updated

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "mac",
  { data_type => "macaddr", is_nullable => 0 },
  "device_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "iface_name",
  { data_type => "text", is_nullable => 0 },
  "iface_type",
  { data_type => "text", is_nullable => 0 },
  "iface_vendor",
  { data_type => "text", is_nullable => 0 },
  "iface_driver",
  { data_type => "text", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "updated",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</mac>

=back

=cut

__PACKAGE__->set_primary_key("mac");

=head1 RELATIONS

=head2 device

Type: belongs_to

Related object: L<Conch::Schema::Result::Device>

=cut

__PACKAGE__->belongs_to(
  "device",
  "Conch::Schema::Result::Device",
  { id => "device_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 device_neighbors

Type: has_many

Related object: L<Conch::Schema::Result::DeviceNeighbor>

=cut

__PACKAGE__->has_many(
  "device_neighbors",
  "Conch::Schema::Result::DeviceNeighbor",
  { "foreign.nic_id" => "self.mac" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_nic_states

Type: has_many

Related object: L<Conch::Schema::Result::DeviceNicState>

=cut

__PACKAGE__->has_many(
  "device_nic_states",
  "Conch::Schema::Result::DeviceNicState",
  { "foreign.nic_id" => "self.mac" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-04-16 19:17:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:euidYXRpt97doOgajuEHeA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
