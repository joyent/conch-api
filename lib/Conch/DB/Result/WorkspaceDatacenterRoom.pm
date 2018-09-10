use utf8;
package Conch::DB::Result::WorkspaceDatacenterRoom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::WorkspaceDatacenterRoom

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<Conch::DB::InflateColumn::Time>

=item * L<Conch::DB::ToJSON>

=back

=cut

__PACKAGE__->load_components("+Conch::DB::InflateColumn::Time", "+Conch::DB::ToJSON");

=head1 TABLE: C<workspace_datacenter_room>

=cut

__PACKAGE__->table("workspace_datacenter_room");

=head1 ACCESSORS

=head2 workspace_id

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
  "workspace_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "datacenter_room_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<workspace_datacenter_room_workspace_id_datacenter_room_id_key>

=over 4

=item * L</workspace_id>

=item * L</datacenter_room_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "workspace_datacenter_room_workspace_id_datacenter_room_id_key",
  ["workspace_id", "datacenter_room_id"],
);

=head1 RELATIONS

=head2 datacenter_room

Type: belongs_to

Related object: L<Conch::DB::Result::DatacenterRoom>

=cut

__PACKAGE__->belongs_to(
  "datacenter_room",
  "Conch::DB::Result::DatacenterRoom",
  { id => "datacenter_room_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 workspace

Type: belongs_to

Related object: L<Conch::DB::Result::Workspace>

=cut

__PACKAGE__->belongs_to(
  "workspace",
  "Conch::DB::Result::Workspace",
  { id => "workspace_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-10 12:42:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r649ScOmXCpeg5x+5L3+Ig


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
