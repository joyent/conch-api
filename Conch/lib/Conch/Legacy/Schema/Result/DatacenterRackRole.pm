use utf8;

package Conch::Legacy::Schema::Result::DatacenterRackRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Legacy::Schema::Result::DatacenterRackRole

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp" );

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

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type     => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable   => 0,
    size          => 16,
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "rack_size",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<datacenter_rack_role_name_rack_size_key>

=over 4

=item * L</name>

=item * L</rack_size>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "datacenter_rack_role_name_rack_size_key",
  [ "name", "rack_size" ],
);

=head1 RELATIONS

=head2 datacenter_racks

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::DatacenterRack>

=cut

__PACKAGE__->has_many(
  "datacenter_racks",
  "Conch::Legacy::Schema::Result::DatacenterRack",
  { "foreign.role" => "self.id" },
  { cascade_copy   => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-12 11:35:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g3GaIYF/OBf3PNXoqYkiZw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
