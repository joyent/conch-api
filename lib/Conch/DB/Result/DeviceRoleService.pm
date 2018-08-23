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

=head1 TABLE: C<device_role_service>

=cut

__PACKAGE__->table("device_role_service");

=head1 ACCESSORS

=head2 device_role_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 device_role_service_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "device_role_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "device_role_service_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<device_role_services_role_id_service_id_key>

=over 4

=item * L</device_role_id>

=item * L</device_role_service_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "device_role_services_role_id_service_id_key",
  ["device_role_id", "device_role_service_id"],
);

=head1 RELATIONS

=head2 device_role

Type: belongs_to

Related object: L<Conch::DB::Result::DeviceRole>

=cut

__PACKAGE__->belongs_to(
  "device_role",
  "Conch::DB::Result::DeviceRole",
  { id => "device_role_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 device_role_service

Type: belongs_to

Related object: L<Conch::DB::Result::DeviceService>

=cut

__PACKAGE__->belongs_to(
  "device_role_service",
  "Conch::DB::Result::DeviceService",
  { id => "device_role_service_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-08-21 11:42:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ted6wfW0VdeKGaPPPFs/lA


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
