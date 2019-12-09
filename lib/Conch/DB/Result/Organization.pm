use utf8;
package Conch::DB::Result::Organization;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::Organization

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<organization>

=cut

__PACKAGE__->table("organization");

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

=head2 deactivated

  data_type: 'timestamp with time zone'
  is_nullable: 1

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
  "deactivated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 organization_build_roles

Type: has_many

Related object: L<Conch::DB::Result::OrganizationBuildRole>

=cut

__PACKAGE__->has_many(
  "organization_build_roles",
  "Conch::DB::Result::OrganizationBuildRole",
  { "foreign.organization_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_organization_roles

Type: has_many

Related object: L<Conch::DB::Result::UserOrganizationRole>

=cut

__PACKAGE__->has_many(
  "user_organization_roles",
  "Conch::DB::Result::UserOrganizationRole",
  { "foreign.organization_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 builds

Type: many_to_many

Composing rels: L</organization_build_roles> -> build

=cut

__PACKAGE__->many_to_many("builds", "organization_build_roles", "build");

=head2 user_accounts

Type: many_to_many

Composing rels: L</user_organization_roles> -> user_account

=cut

__PACKAGE__->many_to_many("user_accounts", "user_organization_roles", "user_account");


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:25Kvlbfpw7/C1PDx/1tyRQ

__PACKAGE__->add_columns(
    '+deactivated' => { is_serializable => 0 },
);

use experimental 'signatures';

=head1 METHODS

=head2 TO_JSON

Include information about the organization's admins and builds, if available.

=cut

sub TO_JSON ($self) {
    my $data = $self->next::method(@_);

    $data->{users} = [
        map {
            my ($user) = $_->related_resultset('user_account')->get_cache->@*;
            +{
                (map +($_ => $user->$_), qw(id name email)),
                role => $_->role,
            };
        }
        $self->related_resultset('user_organization_roles')->get_cache->@*
    ];

    my $cached_obrs = $self->related_resultset('organization_build_roles')->get_cache;
    $data->{builds} = [
        (map {
            my $build = $_->build;
            +{
                (map +($_ => $build->$_), qw(id name description)),
                role => $_->role,
            },
        } $cached_obrs->@*),
    ];

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
