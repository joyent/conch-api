use utf8;
package Conch::DB::Result::Rack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::Rack

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<rack>

=cut

__PACKAGE__->table("rack");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 datacenter_room_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 rack_role_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

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

=head2 serial_number

  data_type: 'text'
  is_nullable: 1

=head2 asset_tag

  data_type: 'text'
  is_nullable: 1

=head2 phase

  data_type: 'enum'
  default_value: 'integration'
  extra: {custom_type_name => "device_phase_enum",list => ["integration","installation","production","diagnostics","decommissioned"]}
  is_nullable: 0

=head2 build_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 1
  size: 16

=head2 links

  data_type: 'text[]'
  default_value: '{}'::text[]
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "datacenter_room_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "rack_role_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
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
  "serial_number",
  { data_type => "text", is_nullable => 1 },
  "asset_tag",
  { data_type => "text", is_nullable => 1 },
  "phase",
  {
    data_type => "enum",
    default_value => "integration",
    extra => {
      custom_type_name => "device_phase_enum",
      list => [
        "integration",
        "installation",
        "production",
        "diagnostics",
        "decommissioned",
      ],
    },
    is_nullable => 0,
  },
  "build_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "links",
  {
    data_type     => "text[]",
    default_value => \"'{}'::text[]",
    is_nullable   => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<rack_datacenter_room_id_name_key>

=over 4

=item * L</datacenter_room_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "rack_datacenter_room_id_name_key",
  ["datacenter_room_id", "name"],
);

=head1 RELATIONS

=head2 build

Type: belongs_to

Related object: L<Conch::DB::Result::Build>

=cut

__PACKAGE__->belongs_to(
  "build",
  "Conch::DB::Result::Build",
  { id => "build_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

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

=head2 device_locations

Type: has_many

Related object: L<Conch::DB::Result::DeviceLocation>

=cut

__PACKAGE__->has_many(
  "device_locations",
  "Conch::DB::Result::DeviceLocation",
  { "foreign.rack_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rack_layouts

Type: has_many

Related object: L<Conch::DB::Result::RackLayout>

=cut

__PACKAGE__->has_many(
  "rack_layouts",
  "Conch::DB::Result::RackLayout",
  { "foreign.rack_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rack_role

Type: belongs_to

Related object: L<Conch::DB::Result::RackRole>

=cut

__PACKAGE__->belongs_to(
  "rack_role",
  "Conch::DB::Result::RackRole",
  { id => "rack_role_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:w+hSP94pWgQJ3o+7UaRvxg

__PACKAGE__->load_components('+Conch::DB::Helper::Row::WithPhase');

__PACKAGE__->add_columns(
    '+phase' => { retrieve_on_insert => 1 },
);

use experimental 'signatures';
use next::XS;

=head1 METHODS

=head2 TO_JSON

Include the rack's build, room, role and full rack name (with room location) when available.

=cut

sub TO_JSON ($self) {
    my $data = $self->next::method(@_);

    foreach my $key (qw(build_name datacenter_room_alias rack_role_name full_rack_name)) {
        $data->{$key} = $self->get_column($key) if $self->has_column_loaded($key);
    }

    return $data;
}

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
