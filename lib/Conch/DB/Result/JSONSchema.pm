use utf8;
package Conch::DB::Result::JSONSchema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::JSONSchema

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<json_schema>

=cut

__PACKAGE__->table("json_schema");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 version

  data_type: 'integer'
  is_nullable: 0

=head2 body

  data_type: 'jsonb'
  is_nullable: 0

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_user_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

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
  "type",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "version",
  { data_type => "integer", is_nullable => 0 },
  "body",
  { data_type => "jsonb", is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_user_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "deactivated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<json_schema_type_name_version_key>

=over 4

=item * L</type>

=item * L</name>

=item * L</version>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "json_schema_type_name_version_key",
  ["type", "name", "version"],
);

=head1 RELATIONS

=head2 created_user

Type: belongs_to

Related object: L<Conch::DB::Result::UserAccount>

=cut

__PACKAGE__->belongs_to(
  "created_user",
  "Conch::DB::Result::UserAccount",
  { id => "created_user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QogBSHwFcZGyKwphDIkDow

__PACKAGE__->add_columns(
  '+version' => { retrieve_on_insert => 1 },
  '+body' => { is_serializable => 0 },
  '+created_user_id' => { is_serializable => 0 },
  '+deactivated' => { is_serializable => 0 },
);

use experimental 'signatures';
use next::XS;
use Mojo::JSON 'from_json';

=head1 METHODS

=head2 TO_JSON

Include information about the JSON Schema's creation user, or user who added the JSON Schema to
hardware (when fetched from a C<hardware_product> context).

=cut

sub TO_JSON ($self) {
  my $data = $self->next::method(@_);

  # we do not need to make the $id URL absolute here, because the document body is not included
  $data->{'$id'} = '/json_schema/'.join('/', $data->@{qw(type name version)});
  $data->{description} = $self->get_column('description') if $self->has_column_loaded('description');

  if (my $user_cache = $self->related_resultset('created_user')->get_cache) {
    $data->{created_user} = +{ map +($_ => $user_cache->[0]->$_), qw(id name email) };
  }

  return $data;
}

=head2 canonical_path

The canonical path to this resource.

=cut

sub canonical_path ($self) {
  return join '/', '/json_schema', map $self->$_, qw(type name version);
}

=head2 schema_document

Returns the actual JSON Schema document itself, suitable for returning to a client or adding to
a L<JSON::Schema::Draft201909> object.

Takes an optional coderef, which takes the result object and returns the value to be used for
the C<$id> property (otherwise, L</canonical_path> will be used).

=cut

sub schema_document ($self, $id_generator = undef) {
  my $document = from_json($self->body);
  # we make the $id absolute here so it can always be traced back to its source,
  # and never confused with a similar schema document from another host
  $document->{'$id'} = $id_generator ? $id_generator->($self) : $self->canonical_path;

  if (my $user_cache = $self->related_resultset('created_user')->get_cache) {
    $document->{'$comment'} = join "\n", $document->{'$comment'} // (),
      'created by '.$user_cache->[0]->name.' <'.$user_cache->[0]->email.'>';
  }

  $document->{'x-json_schema_id'} = $self->id;
  return $document;
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
# vim: set sts=2 sw=2 et :
