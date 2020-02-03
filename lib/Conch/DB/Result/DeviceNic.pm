use utf8;
package Conch::DB::Result::DeviceNic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::DeviceNic

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<device_nic>

=cut

__PACKAGE__->table("device_nic");

=head1 ACCESSORS

=head2 mac

  data_type: 'macaddr'
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

=head2 state

  data_type: 'text'
  is_nullable: 1

=head2 ipaddr

  data_type: 'inet'
  is_nullable: 1

=head2 mtu

  data_type: 'integer'
  is_nullable: 1

=head2 device_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "mac",
  { data_type => "macaddr", is_nullable => 0 },
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
  "state",
  { data_type => "text", is_nullable => 1 },
  "ipaddr",
  { data_type => "inet", is_nullable => 1 },
  "mtu",
  { data_type => "integer", is_nullable => 1 },
  "device_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
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

Related object: L<Conch::DB::Result::Device>

=cut

__PACKAGE__->belongs_to(
  "device",
  "Conch::DB::Result::Device",
  { id => "device_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 device_neighbor

Type: might_have

Related object: L<Conch::DB::Result::DeviceNeighbor>

=cut

__PACKAGE__->might_have(
  "device_neighbor",
  "Conch::DB::Result::DeviceNeighbor",
  { "foreign.mac" => "self.mac" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gRrqZ7XzKE56gbryiOLzsw

__PACKAGE__->add_columns(
    '+created' => { is_serializable => 0 },
    '+updated' => { is_serializable => 0 },
    '+deactivated' => { is_serializable => 0 },
);

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
