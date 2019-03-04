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
  "az",
  { data_type => "text", is_nullable => 0 },
  "alias",
  { data_type => "text", is_nullable => 0 },
  "vendor_name",
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

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

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

=head2 datacenter_racks

Type: has_many

Related object: L<Conch::DB::Result::DatacenterRack>

=cut

__PACKAGE__->has_many(
  "datacenter_racks",
  "Conch::DB::Result::DatacenterRack",
  { "foreign.datacenter_room_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspace_datacenter_rooms

Type: has_many

Related object: L<Conch::DB::Result::WorkspaceDatacenterRoom>

=cut

__PACKAGE__->has_many(
  "workspace_datacenter_rooms",
  "Conch::DB::Result::WorkspaceDatacenterRoom",
  { "foreign.datacenter_room_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspaces

Type: many_to_many

Composing rels: L</workspace_datacenter_rooms> -> workspace

=cut

__PACKAGE__->many_to_many("workspaces", "workspace_datacenter_rooms", "workspace");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-03-01 17:08:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ni3tUlJIenaCZf9Y1PhUJQ

sub TO_JSON {
    my $self = shift;

    my $data = $self->next::method(@_);
    $data->{datacenter} = delete $data->{datacenter_id};
    return $data;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
