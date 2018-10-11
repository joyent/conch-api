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

=head2 id

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

=head2 state

  data_type: 'text'
  is_nullable: 0

=head2 health

  data_type: 'text'
  is_nullable: 0

=head2 graduated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 deactivated

  data_type: 'timestamp with time zone'
  is_nullable: 1

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

=head2 latest_triton_reboot

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 triton_uuid

  data_type: 'uuid'
  is_nullable: 1
  size: 16

=head2 asset_tag

  data_type: 'text'
  is_nullable: 1

=head2 triton_setup

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 hostname

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "system_uuid",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "hardware_product_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "state",
  { data_type => "text", is_nullable => 0 },
  "health",
  { data_type => "text", is_nullable => 0 },
  "graduated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "deactivated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
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
  "latest_triton_reboot",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "triton_uuid",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "asset_tag",
  { data_type => "text", is_nullable => 1 },
  "triton_setup",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "hostname",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<device_system_uuid_key>

=over 4

=item * L</system_uuid>

=back

=cut

__PACKAGE__->add_unique_constraint("device_system_uuid_key", ["system_uuid"]);

=head1 RELATIONS

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

=head2 device_environment

Type: might_have

Related object: L<Conch::DB::Result::DeviceEnvironment>

=cut

__PACKAGE__->might_have(
  "device_environment",
  "Conch::DB::Result::DeviceEnvironment",
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

=head2 device_logs

Type: has_many

Related object: L<Conch::DB::Result::DeviceLog>

=cut

__PACKAGE__->has_many(
  "device_logs",
  "Conch::DB::Result::DeviceLog",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_memories

Type: has_many

Related object: L<Conch::DB::Result::DeviceMemory>

=cut

__PACKAGE__->has_many(
  "device_memories",
  "Conch::DB::Result::DeviceMemory",
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

=head2 device_spec

Type: might_have

Related object: L<Conch::DB::Result::DeviceSpec>

=cut

__PACKAGE__->might_have(
  "device_spec",
  "Conch::DB::Result::DeviceSpec",
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-17 14:52:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4V3uuMhmsA47LT8AHUR7hw

__PACKAGE__->add_columns(
    '+deactivated' => { is_serializable => 0 },
);

sub TO_JSON {
    my $self = shift;

    my $data = $self->next::method(@_);
    $data->{hardware_product} = delete $data->{hardware_product_id};
    return $data;
}

use Mojo::JSON 'from_json';

=head2 latest_report_data

Returns the JSON-decoded content from the most recent device report.

=cut

sub latest_report_data {
    my $self = shift;

    my $json = $self->self_rs->latest_device_report->get_column('report')->single;

    defined $json ? from_json($json) : undef;
}

=head2 latest_report_matches

Checks if the latest report's json matches the passed-in json-encoded content (comparing using
native jsonb operators).

=cut

sub latest_report_matches {
    my ($self, $jsonb) = @_;

    $self->self_rs
        ->latest_device_report
        ->as_subselect_rs
        ->search({ report => \[ '= ?::jsonb', $jsonb ] })
        ->count;
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
