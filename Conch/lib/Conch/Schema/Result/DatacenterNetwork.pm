use utf8;
package Conch::Schema::Result::DatacenterNetwork;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::DatacenterNetwork

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<datacenter_network>

=cut

__PACKAGE__->table("datacenter_network");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 datacenter_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 subnet

  data_type: 'cidr'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 deactivated

  data_type: 'timestamp with time zone'
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
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "datacenter_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "subnet",
  { data_type => "cidr", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "deactivated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
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

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 datacenter

Type: belongs_to

Related object: L<Conch::Schema::Result::Datacenter>

=cut

__PACKAGE__->belongs_to(
  "datacenter",
  "Conch::Schema::Result::Datacenter",
  { id => "datacenter_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 datacenter_room_networks

Type: has_many

Related object: L<Conch::Schema::Result::DatacenterRoomNetwork>

=cut

__PACKAGE__->has_many(
  "datacenter_room_networks",
  "Conch::Schema::Result::DatacenterRoomNetwork",
  { "foreign.network_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-07-19 13:15:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CWFMyJBN7/Ymwb8n4d3xjg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
