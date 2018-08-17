use utf8;
package Conch::DB::Result::DeviceRoleService;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::DeviceRoleService

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

=head1 TABLE: C<device_role_services>

=cut

__PACKAGE__->table("device_role_services");

=head1 ACCESSORS

=head2 role_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 service_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "role_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "service_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<device_role_services_role_id_service_id_key>

=over 4

=item * L</role_id>

=item * L</service_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "device_role_services_role_id_service_id_key",
  ["role_id", "service_id"],
);

=head1 RELATIONS

=head2 role

Type: belongs_to

Related object: L<Conch::DB::Result::DeviceRole>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Conch::DB::Result::DeviceRole",
  { id => "role_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 service

Type: belongs_to

Related object: L<Conch::DB::Result::DeviceService>

=cut

__PACKAGE__->belongs_to(
  "service",
  "Conch::DB::Result::DeviceService",
  { id => "service_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-08-15 16:00:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FTKJ414/weWalT1zdnEraQ


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
