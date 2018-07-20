use utf8;
package Conch::DB::Result::ValidationState;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::ValidationState

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

=head1 TABLE: C<validation_state>

=cut

__PACKAGE__->table("validation_state");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: uuid_generate_v4()
  is_nullable: 0
  size: 16

=head2 device_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 validation_plan_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 status

  data_type: 'enum'
  default_value: 'processing'
  extra: {custom_type_name => "validation_status_enum",list => ["error","pass","fail","processing"]}
  is_nullable: 0

=head2 completed

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"uuid_generate_v4()",
    is_nullable => 0,
    size => 16,
  },
  "device_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "validation_plan_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "status",
  {
    data_type => "enum",
    default_value => "processing",
    extra => {
      custom_type_name => "validation_status_enum",
      list => ["error", "pass", "fail", "processing"],
    },
    is_nullable => 0,
  },
  "completed",
  { data_type => "timestamp with time zone", is_nullable => 1 },
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

=head2 validation_plan

Type: belongs_to

Related object: L<Conch::DB::Result::ValidationPlan>

=cut

__PACKAGE__->belongs_to(
  "validation_plan",
  "Conch::DB::Result::ValidationPlan",
  { id => "validation_plan_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 validation_state_members

Type: has_many

Related object: L<Conch::DB::Result::ValidationStateMember>

=cut

__PACKAGE__->has_many(
  "validation_state_members",
  "Conch::DB::Result::ValidationStateMember",
  { "foreign.validation_state_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_results

Type: many_to_many

Composing rels: L</validation_state_members> -> validation_result

=cut

__PACKAGE__->many_to_many(
  "validation_results",
  "validation_state_members",
  "validation_result",
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-07-20 14:04:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:09Klw3amzXUs6XtPbr70Zg


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
