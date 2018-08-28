use utf8;
package Conch::DB::Result::DatacenterRackRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::DatacenterRackRole

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<datacenter_rack_role>

=cut

__PACKAGE__->table("datacenter_rack_role");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 rack_size

  data_type: 'integer'
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
  "name",
  { data_type => "text", is_nullable => 0 },
  "rack_size",
  { data_type => "integer", is_nullable => 0 },
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

=head2 C<datacenter_rack_role_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("datacenter_rack_role_name_key", ["name"]);

=head2 C<datacenter_rack_role_name_rack_size_key>

=over 4

=item * L</name>

=item * L</rack_size>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "datacenter_rack_role_name_rack_size_key",
  ["name", "rack_size"],
);

=head1 RELATIONS

=head2 datacenter_racks

Type: has_many

Related object: L<Conch::DB::Result::DatacenterRack>

=cut

__PACKAGE__->has_many(
  "datacenter_racks",
  "Conch::DB::Result::DatacenterRack",
  { "foreign.datacenter_rack_role_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-17 14:52:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sOI9flK9L0dRIv1JoAfx4A


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
