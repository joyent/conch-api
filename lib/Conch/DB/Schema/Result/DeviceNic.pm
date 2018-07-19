use utf8;
package Conch::DB::Schema::Result::DeviceNic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Schema::Result::DeviceNic

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::Helper::Row::ToJSON>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Helper::Row::ToJSON");

=head1 TABLE: C<device_nic>

=cut

__PACKAGE__->table("device_nic");

=head1 ACCESSORS

=head2 mac

  data_type: 'macaddr'
  is_nullable: 0

=head2 device_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

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
  "mac",
  { data_type => "macaddr", is_nullable => 0 },
  "device_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "iface_name",
  { data_type => "text", is_nullable => 0 },
  "iface_type",
  { data_type => "text", is_nullable => 0 },
  "iface_vendor",
  { data_type => "text", is_nullable => 0 },
  "iface_driver",
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

=item * L</mac>

=back

=cut

__PACKAGE__->set_primary_key("mac");

=head1 RELATIONS

=head2 device

Type: belongs_to

Related object: L<Conch::DB::Schema::Result::Device>

=cut

__PACKAGE__->belongs_to(
  "device",
  "Conch::DB::Schema::Result::Device",
  { id => "device_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 device_neighbor

Type: might_have

Related object: L<Conch::DB::Schema::Result::DeviceNeighbor>

=cut

__PACKAGE__->might_have(
  "device_neighbor",
  "Conch::DB::Schema::Result::DeviceNeighbor",
  { "foreign.mac" => "self.mac" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_nic_state

Type: might_have

Related object: L<Conch::DB::Schema::Result::DeviceNicState>

=cut

__PACKAGE__->might_have(
  "device_nic_state",
  "Conch::DB::Schema::Result::DeviceNicState",
  { "foreign.mac" => "self.mac" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-07-16 11:13:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+os7yL0yLqfSaZPHZbIibQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
