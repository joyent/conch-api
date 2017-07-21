use utf8;
package Conch::Schema::Result::DeviceValidate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::DeviceValidate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<device_validate>

=cut

__PACKAGE__->table("device_validate");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 report_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 device_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 component_type

  data_type: 'text'
  is_nullable: 0

=head2 component_name

  data_type: 'text'
  is_nullable: 0

=head2 component_id

  data_type: 'uuid'
  is_nullable: 1
  size: 16

=head2 criteria_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 1
  size: 16

=head2 metric

  data_type: 'integer'
  is_nullable: 1

=head2 log

  data_type: 'text'
  is_nullable: 1

=head2 status

  data_type: 'boolean'
  is_nullable: 0

=head2 created

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
  "report_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "device_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "component_type",
  { data_type => "text", is_nullable => 0 },
  "component_name",
  { data_type => "text", is_nullable => 0 },
  "component_id",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "criteria_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "metric",
  { data_type => "integer", is_nullable => 1 },
  "log",
  { data_type => "text", is_nullable => 1 },
  "status",
  { data_type => "boolean", is_nullable => 0 },
  "created",
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

=head2 criteria

Type: belongs_to

Related object: L<Conch::Schema::Result::DeviceValidateCriteria>

=cut

__PACKAGE__->belongs_to(
  "criteria",
  "Conch::Schema::Result::DeviceValidateCriteria",
  { id => "criteria_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 device

Type: belongs_to

Related object: L<Conch::Schema::Result::Device>

=cut

__PACKAGE__->belongs_to(
  "device",
  "Conch::Schema::Result::Device",
  { id => "device_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 report

Type: belongs_to

Related object: L<Conch::Schema::Result::DeviceReport>

=cut

__PACKAGE__->belongs_to(
  "report",
  "Conch::Schema::Result::DeviceReport",
  { id => "report_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-07-21 13:21:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fMD3VGbapMTdPQZkGeGQiA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
