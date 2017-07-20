use utf8;
package Conch::Schema::Result::UserDatacenterRoomAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::UserDatacenterRoomAccess

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

=head1 TABLE: C<user_datacenter_room_access>

=cut

__PACKAGE__->table("user_datacenter_room_access");

=head1 ACCESSORS

=head2 user_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 datacenter_room_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "datacenter_room_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</datacenter_room_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "datacenter_room_id");

=head1 RELATIONS

=head2 datacenter_room

Type: belongs_to

Related object: L<Conch::Schema::Result::DatacenterRoom>

=cut

__PACKAGE__->belongs_to(
  "datacenter_room",
  "Conch::Schema::Result::DatacenterRoom",
  { id => "datacenter_room_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<Conch::Schema::Result::UserAccount>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Conch::Schema::Result::UserAccount",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-07-20 15:16:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zvt9jYASdoFoLz+srjhcZQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
