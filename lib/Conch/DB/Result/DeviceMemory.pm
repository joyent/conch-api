use utf8;
package Conch::DB::Result::DeviceMemory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::DeviceMemory

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

=head1 TABLE: C<device_memory>

=cut

__PACKAGE__->table("device_memory");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 device_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 serial_number

  data_type: 'text'
  is_nullable: 0

=head2 vendor

  data_type: 'text'
  is_nullable: 0

=head2 model

  data_type: 'text'
  is_nullable: 0

=head2 bank

  data_type: 'text'
  is_nullable: 0

=head2 speed

  data_type: 'text'
  is_nullable: 0

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
  "device_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "serial_number",
  { data_type => "text", is_nullable => 0 },
  "vendor",
  { data_type => "text", is_nullable => 0 },
  "model",
  { data_type => "text", is_nullable => 0 },
  "bank",
  { data_type => "text", is_nullable => 0 },
  "speed",
  { data_type => "text", is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-08-15 16:00:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RXzsEkT4aWJSthjR1G0zQw


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
