use utf8;
package Conch::DB::Result::Relay;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::Relay

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

=head1 TABLE: C<relay>

=cut

__PACKAGE__->table("relay");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 alias

  data_type: 'text'
  is_nullable: 1

=head2 version

  data_type: 'text'
  is_nullable: 1

=head2 ipaddr

  data_type: 'inet'
  is_nullable: 1

=head2 ssh_port

  data_type: 'integer'
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
  { data_type => "text", is_nullable => 0 },
  "alias",
  { data_type => "text", is_nullable => 1 },
  "version",
  { data_type => "text", is_nullable => 1 },
  "ipaddr",
  { data_type => "inet", is_nullable => 1 },
  "ssh_port",
  { data_type => "integer", is_nullable => 1 },
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

=head2 device_relay_connections

Type: has_many

Related object: L<Conch::DB::Result::DeviceRelayConnection>

=cut

__PACKAGE__->has_many(
  "device_relay_connections",
  "Conch::DB::Result::DeviceRelayConnection",
  { "foreign.relay_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_relay_connections

Type: has_many

Related object: L<Conch::DB::Result::UserRelayConnection>

=cut

__PACKAGE__->has_many(
  "user_relay_connections",
  "Conch::DB::Result::UserRelayConnection",
  { "foreign.relay_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-07-20 14:04:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tmnn8I2h1yDmLQFBk5PgjQ


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
