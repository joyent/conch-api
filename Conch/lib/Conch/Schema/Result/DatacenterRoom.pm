use utf8;
package Conch::Schema::Result::DatacenterRoom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::DatacenterRoom

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

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<datacenter_room>

=cut

__PACKAGE__->table("datacenter_room");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 datacenter

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 az

  data_type: 'text'
  is_nullable: 0

=head2 alias

  data_type: 'text'
  is_nullable: 1

=head2 vendor_name

  data_type: 'text'
  is_nullable: 1

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
  "datacenter",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "az",
  { data_type => "text", is_nullable => 0 },
  "alias",
  { data_type => "text", is_nullable => 1 },
  "vendor_name",
  { data_type => "text", is_nullable => 1 },
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
  { id => "datacenter" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 datacenter_racks

Type: has_many

Related object: L<Conch::Schema::Result::DatacenterRack>

=cut

__PACKAGE__->has_many(
  "datacenter_racks",
  "Conch::Schema::Result::DatacenterRack",
  { "foreign.datacenter_room_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 datacenter_room_networks

Type: has_many

Related object: L<Conch::Schema::Result::DatacenterRoomNetwork>

=cut

__PACKAGE__->has_many(
  "datacenter_room_networks",
  "Conch::Schema::Result::DatacenterRoomNetwork",
  { "foreign.datacenter_room_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_datacenter_room_accesses

Type: has_many

Related object: L<Conch::Schema::Result::UserDatacenterRoomAccess>

=cut

__PACKAGE__->has_many(
  "user_datacenter_room_accesses",
  "Conch::Schema::Result::UserDatacenterRoomAccess",
  { "foreign.datacenter_room_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspace_datacenter_rooms

Type: has_many

Related object: L<Conch::Schema::Result::WorkspaceDatacenterRoom>

=cut

__PACKAGE__->has_many(
  "workspace_datacenter_rooms",
  "Conch::Schema::Result::WorkspaceDatacenterRoom",
  { "foreign.datacenter_room_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: many_to_many

Composing rels: L</user_datacenter_room_accesses> -> user

=cut

__PACKAGE__->many_to_many("users", "user_datacenter_room_accesses", "user");


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-10-23 16:37:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cK7Q8KloX+pKpi39Z13DAA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
