use utf8;
package Conch::DB::Result::Device;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::Device

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<device>

=cut

__PACKAGE__->table("device");

=head1 ACCESSORS

=head2 serial_number

  data_type: 'text'
  is_nullable: 0

=head2 system_uuid

  data_type: 'uuid'
  is_nullable: 1
  size: 16

=head2 hardware_product_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 health

  data_type: 'enum'
  extra: {custom_type_name => "device_health_enum",list => ["error","fail","unknown","pass"]}
  is_nullable: 0

=head2 last_seen

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

=head2 uptime_since

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 validated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 asset_tag

  data_type: 'text'
  is_nullable: 1

=head2 hostname

  data_type: 'text'
  is_nullable: 1

=head2 phase

  data_type: 'enum'
  default_value: 'integration'
  extra: {custom_type_name => "device_phase_enum",list => ["integration","installation","production","diagnostics","decommissioned"]}
  is_nullable: 0

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 links

  data_type: 'text[]'
  default_value: '{}'::text[]
  is_nullable: 0

=head2 build_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 1
  size: 16

=cut

__PACKAGE__->add_columns(
  "serial_number",
  { data_type => "text", is_nullable => 0 },
  "system_uuid",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "hardware_product_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "health",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "device_health_enum",
      list => ["error", "fail", "unknown", "pass"],
    },
    is_nullable => 0,
  },
  "last_seen",
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
  "uptime_since",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "validated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "asset_tag",
  { data_type => "text", is_nullable => 1 },
  "hostname",
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
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "links",
  {
    data_type     => "text[]",
    default_value => \"'{}'::text[]",
    is_nullable   => 0,
  },
  "build_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<device_serial_number_key>

=over 4

=item * L</serial_number>

=back

=cut

__PACKAGE__->add_unique_constraint("device_serial_number_key", ["serial_number"]);

=head2 C<device_system_uuid_key>

=over 4

=item * L</system_uuid>

=back

=cut

__PACKAGE__->add_unique_constraint("device_system_uuid_key", ["system_uuid"]);

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

=head2 device_disks

Type: has_many

Related object: L<Conch::DB::Result::DeviceDisk>

=cut

__PACKAGE__->has_many(
  "device_disks",
  "Conch::DB::Result::DeviceDisk",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_location

Type: might_have

Related object: L<Conch::DB::Result::DeviceLocation>

=cut

__PACKAGE__->might_have(
  "device_location",
  "Conch::DB::Result::DeviceLocation",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_nics

Type: has_many

Related object: L<Conch::DB::Result::DeviceNic>

=cut

__PACKAGE__->has_many(
  "device_nics",
  "Conch::DB::Result::DeviceNic",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_relay_connections

Type: has_many

Related object: L<Conch::DB::Result::DeviceRelayConnection>

=cut

__PACKAGE__->has_many(
  "device_relay_connections",
  "Conch::DB::Result::DeviceRelayConnection",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_reports

Type: has_many

Related object: L<Conch::DB::Result::DeviceReport>

=cut

__PACKAGE__->has_many(
  "device_reports",
  "Conch::DB::Result::DeviceReport",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_settings

Type: has_many

Related object: L<Conch::DB::Result::DeviceSetting>

=cut

__PACKAGE__->has_many(
  "device_settings",
  "Conch::DB::Result::DeviceSetting",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hardware_product

Type: belongs_to

Related object: L<Conch::DB::Result::HardwareProduct>

=cut

__PACKAGE__->belongs_to(
  "hardware_product",
  "Conch::DB::Result::HardwareProduct",
  { id => "hardware_product_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 validation_results

Type: has_many

Related object: L<Conch::DB::Result::ValidationResult>

=cut

__PACKAGE__->has_many(
  "validation_results",
  "Conch::DB::Result::ValidationResult",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_states

Type: has_many

Related object: L<Conch::DB::Result::ValidationState>

=cut

__PACKAGE__->has_many(
  "validation_states",
  "Conch::DB::Result::ValidationState",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 relays

Type: many_to_many

Composing rels: L</device_relay_connections> -> relay

=cut

__PACKAGE__->many_to_many("relays", "device_relay_connections", "relay");


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ygCrs0YElHPOZ3jUN4DWUg

__PACKAGE__->load_components('+Conch::DB::Helper::Row::WithPhase');

use experimental 'signatures';

=head1 METHODS

=head2 TO_JSON

Include information about the device's rack location, when available and still relevant

=cut

sub TO_JSON ($self) {
    my $data = $self->next::method(@_);

    foreach my $key (qw(build_name sku)) {
        $data->{$key} = $self->get_column($key) if $self->has_column_loaded($key);
    }

    # include location information, when available and still relevant
    # (see $device_rs->with_device_location)
    if ($self->has_column_loaded('rack_id') and $self->phase_cmp('production') < 0) {
        $data->@{qw(rack_id rack_unit_start rack_name)} =
            map $self->get_column($_), qw(rack_id rack_unit_start rack_name);
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
