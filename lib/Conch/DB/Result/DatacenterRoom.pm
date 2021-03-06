use utf8;
package Conch::DB::Result::DatacenterRoom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::DatacenterRoom

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<datacenter_room>

=cut

__PACKAGE__->table("datacenter_room");

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

=head2 az

  data_type: 'text'
  is_nullable: 0

=head2 alias

  data_type: 'text'
  is_nullable: 0

=head2 vendor_name

  data_type: 'text'
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
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "datacenter_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "az",
  { data_type => "text", is_nullable => 0 },
  "alias",
  { data_type => "text", is_nullable => 0 },
  "vendor_name",
  { data_type => "text", is_nullable => 0 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<datacenter_room_alias_key>

=over 4

=item * L</alias>

=back

=cut

__PACKAGE__->add_unique_constraint("datacenter_room_alias_key", ["alias"]);

=head2 C<datacenter_room_vendor_name_key>

=over 4

=item * L</vendor_name>

=back

=cut

__PACKAGE__->add_unique_constraint("datacenter_room_vendor_name_key", ["vendor_name"]);

=head1 RELATIONS

=head2 datacenter

Type: belongs_to

Related object: L<Conch::DB::Result::Datacenter>

=cut

__PACKAGE__->belongs_to(
  "datacenter",
  "Conch::DB::Result::Datacenter",
  { id => "datacenter_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 racks

Type: has_many

Related object: L<Conch::DB::Result::Rack>

=cut

__PACKAGE__->has_many(
  "racks",
  "Conch::DB::Result::Rack",
  { "foreign.datacenter_room_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/HdkgTQ3OY7FN8f1enwONg

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
