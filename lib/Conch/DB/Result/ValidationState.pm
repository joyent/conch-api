use utf8;
package Conch::DB::Result::ValidationState;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::ValidationState

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

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

=head2 device_report_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

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
  "device_report_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
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

=head2 device_report

Type: belongs_to

Related object: L<Conch::DB::Result::DeviceReport>

=cut

__PACKAGE__->belongs_to(
  "device_report",
  "Conch::DB::Result::DeviceReport",
  { id => "device_report_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-10 16:06:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gkC6RKtvMTPS5Y1V8IlugA

sub TO_JSON {
    my $self = shift;

    my $data = $self->next::method(@_);

    # add validation_results data, if it has been prefetched
    if (my $cached_members = $self->related_resultset('validation_state_members')->get_cache) {
        $data->{results} = [
            map {
                my $cached_result = $_->related_resultset('validation_result')->get_cache;
                # cache is always a listref even for a belongs_to relationship
                $cached_result ? $cached_result->[0]->TO_JSON : ()
            }
            $cached_members->@*
        ];
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
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
