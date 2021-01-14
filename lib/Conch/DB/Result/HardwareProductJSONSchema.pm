use utf8;
package Conch::DB::Result::HardwareProductJSONSchema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::HardwareProductJSONSchema

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<hardware_product_json_schema>

=cut

__PACKAGE__->table("hardware_product_json_schema");

=head1 ACCESSORS

=head2 hardware_product_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 json_schema_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 added

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 added_user_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "hardware_product_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "json_schema_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "added",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "added_user_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</hardware_product_id>

=item * L</json_schema_id>

=back

=cut

__PACKAGE__->set_primary_key("hardware_product_id", "json_schema_id");

=head1 RELATIONS

=head2 added_user

Type: belongs_to

Related object: L<Conch::DB::Result::UserAccount>

=cut

__PACKAGE__->belongs_to(
  "added_user",
  "Conch::DB::Result::UserAccount",
  { id => "added_user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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

=head2 json_schema

Type: belongs_to

Related object: L<Conch::DB::Result::JSONSchema>

=cut

__PACKAGE__->belongs_to(
  "json_schema",
  "Conch::DB::Result::JSONSchema",
  { id => "json_schema_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:slHJqoQD5dDu2v/PgWKo0A


1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
