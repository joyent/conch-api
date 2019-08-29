use utf8;
package Conch::DB::Result::DeviceReport;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::DeviceReport

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<device_report>

=cut

__PACKAGE__->table("device_report");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 report

  data_type: 'jsonb'
  is_nullable: 0

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 retain

  data_type: 'boolean'
  is_nullable: 1

=head2 device_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "report",
  { data_type => "jsonb", is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "retain",
  { data_type => "boolean", is_nullable => 1 },
  "device_id",
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

=head2 validation_states

Type: has_many

Related object: L<Conch::DB::Result::ValidationState>

=cut

__PACKAGE__->has_many(
  "validation_states",
  "Conch::DB::Result::ValidationState",
  { "foreign.device_report_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DknxBwVAxO4T5RbebwF/qg

__PACKAGE__->add_columns(
    '+retain' => { is_serializable => 0 },
);

use experimental 'signatures';
use Mojo::JSON 'from_json';

sub TO_JSON ($self) {
    my $data = $self->next::method(@_);
    $data->{report} = from_json($data->{report}) if defined $data->{report};

    return $data;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
