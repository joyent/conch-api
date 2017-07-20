use utf8;
package Conch::Schema::Result::UserAccount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::UserAccount

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

=head1 TABLE: C<user_account>

=cut

__PACKAGE__->table("user_account");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 password_hash

  data_type: 'text'
  is_nullable: 0

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 last_login

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "password_hash",
  { data_type => "text", is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "last_login",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_account_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("user_account_name_key", ["name"]);

=head1 RELATIONS

=head2 user_datacenter_room_accesses

Type: has_many

Related object: L<Conch::Schema::Result::UserDatacenterRoomAccess>

=cut

__PACKAGE__->has_many(
  "user_datacenter_room_accesses",
  "Conch::Schema::Result::UserDatacenterRoomAccess",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 datacenter_rooms

Type: many_to_many

Composing rels: L</user_datacenter_room_accesses> -> datacenter_room

=cut

__PACKAGE__->many_to_many(
  "datacenter_rooms",
  "user_datacenter_room_accesses",
  "datacenter_room",
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-07-20 15:16:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ihXYUPsQClLQVnVU69X0ww


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
