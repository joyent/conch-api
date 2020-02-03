use utf8;
package Conch::DB::Result::Build;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::Build

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<build>

=cut

__PACKAGE__->table("build");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 started

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 completed

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 completed_user_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 1
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
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "started",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "completed",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "completed_user_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<build_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("build_name_key", ["name"]);

=head1 RELATIONS

=head2 completed_user

Type: belongs_to

Related object: L<Conch::DB::Result::UserAccount>

=cut

__PACKAGE__->belongs_to(
  "completed_user",
  "Conch::DB::Result::UserAccount",
  { id => "completed_user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 devices

Type: has_many

Related object: L<Conch::DB::Result::Device>

=cut

__PACKAGE__->has_many(
  "devices",
  "Conch::DB::Result::Device",
  { "foreign.build_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organization_build_roles

Type: has_many

Related object: L<Conch::DB::Result::OrganizationBuildRole>

=cut

__PACKAGE__->has_many(
  "organization_build_roles",
  "Conch::DB::Result::OrganizationBuildRole",
  { "foreign.build_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 racks

Type: has_many

Related object: L<Conch::DB::Result::Rack>

=cut

__PACKAGE__->has_many(
  "racks",
  "Conch::DB::Result::Rack",
  { "foreign.build_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_build_roles

Type: has_many

Related object: L<Conch::DB::Result::UserBuildRole>

=cut

__PACKAGE__->has_many(
  "user_build_roles",
  "Conch::DB::Result::UserBuildRole",
  { "foreign.build_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organizations

Type: many_to_many

Composing rels: L</organization_build_roles> -> organization

=cut

__PACKAGE__->many_to_many("organizations", "organization_build_roles", "organization");

=head2 user_accounts

Type: many_to_many

Composing rels: L</user_build_roles> -> user_account

=cut

__PACKAGE__->many_to_many("user_accounts", "user_build_roles", "user_account");


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/yxSdyffA8uJFiFb4mEu6A

__PACKAGE__->add_columns(
    '+completed_user_id' => { is_serializable => 0 },
);

use experimental 'signatures';

=head1 METHODS

=head2 TO_JSON

Include information about the build's admins and user who marked the build completed.

=cut

sub TO_JSON ($self) {
    my $data = $self->next::method(@_);

    $data->{admins} = [
        map {
            my ($user) = $_->related_resultset('user_account')->get_cache->@*;
            +{ map +($_ => $user->$_), qw(id name email) };
        }
        $self->related_resultset('user_build_roles')->get_cache->@*
    ];

    my ($completed_user) = $data->{completed} && $self->related_resultset('completed_user')->get_cache->@*;
    $data->{completed_user} =
        $completed_user ? +{ map +($_ => $completed_user->$_), qw(id name email) }
      : undef;

    if ($self->has_column_loaded('device_health')) {
        my @enum = $self->related_resultset('devices')->result_source->column_info('health')->{extra}{list}->@*;
        $data->{device_health}->@{@enum} = (0)x@enum;

        my %column_data = map $_->@*, $self->get_column('device_health')->@*;
        $data->{device_health}->@{keys %column_data} = map int, values %column_data;
    }

    if ($self->has_column_loaded('device_phases')) {
        my @enum = $self->related_resultset('devices')->result_source->column_info('phase')->{extra}{list}->@*;
        $data->{device_phases}->@{@enum} = (0)x@enum;

        my %column_data = map $_->@*, $self->get_column('device_phases')->@*;
        $data->{device_phases}->@{keys %column_data} = map int, values %column_data;
    }

    if ($self->has_column_loaded('rack_phases')) {
        my @enum = $self->related_resultset('racks')->result_source->column_info('phase')->{extra}{list}->@*;
        $data->{rack_phases}->@{@enum} = (0)x@enum;

        my %column_data = map $_->@*, $self->get_column('rack_phases')->@*;
        $data->{rack_phases}->@{keys %column_data} = map int, values %column_data;
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
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
