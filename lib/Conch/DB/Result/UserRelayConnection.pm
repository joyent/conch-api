use utf8;
package Conch::DB::Result::UserRelayConnection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::UserRelayConnection

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<user_relay_connection>

=cut

__PACKAGE__->table("user_relay_connection");

=head1 ACCESSORS

=head2 user_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 relay_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 first_seen

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 last_seen

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "relay_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "first_seen",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "last_seen",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</relay_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "relay_id");

=head1 RELATIONS

=head2 relay

Type: belongs_to

Related object: L<Conch::DB::Result::Relay>

=cut

__PACKAGE__->belongs_to(
  "relay",
  "Conch::DB::Result::Relay",
  { id => "relay_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user_account

Type: belongs_to

Related object: L<Conch::DB::Result::UserAccount>

=cut

__PACKAGE__->belongs_to(
  "user_account",
  "Conch::DB::Result::UserAccount",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aR4gZ+TwJhzfL38PFNfm3g

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
