use utf8;
package Conch::Schema::Result::WorkspaceDatacenterRoom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::WorkspaceDatacenterRoom

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

=head1 TABLE: C<workspace_datacenter_room>

=cut

__PACKAGE__->table("workspace_datacenter_room");

=head1 ACCESSORS

=head2 workspace_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 1
  size: 16

=head2 datacenter_room_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 1
  size: 16

=cut

__PACKAGE__->add_columns(
  "workspace_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "datacenter_room_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
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

Related object: L<Conch::Schema::Result::DatacenterRoom>

=cut

__PACKAGE__->belongs_to(
  "datacenter_room",
  "Conch::Schema::Result::DatacenterRoom",
  { id => "datacenter_room_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 workspace

Type: belongs_to

Related object: L<Conch::Schema::Result::Workspace>

=cut

__PACKAGE__->belongs_to(
  "workspace",
  "Conch::Schema::Result::Workspace",
  { id => "workspace_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-10-23 16:37:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gE9ek3YJLgma3A1ENfvTyQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
