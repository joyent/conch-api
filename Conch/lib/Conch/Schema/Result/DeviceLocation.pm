use utf8;
package Conch::Schema::Result::DeviceLocation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::DeviceLocation

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

=head1 TABLE: C<device_location>

=cut

__PACKAGE__->table("device_location");

=head1 ACCESSORS

=head2 device_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 location

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 rack_unit

  data_type: 'integer'
  is_nullable: 0

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
  "device_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "location",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "rack_unit",
  { data_type => "integer", is_nullable => 0 },
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

=item * L</device_id>

=back

=cut

__PACKAGE__->set_primary_key("device_id");

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

=head2 location

Type: belongs_to

Related object: L<Conch::Schema::Result::DatacenterRack>

=cut

__PACKAGE__->belongs_to(
  "location",
  "Conch::Schema::Result::DatacenterRack",
  { id => "location" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-04-13 05:24:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:26IJxjpBABzsWKv1W8Cwcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
