package Conch::DB::ResultSet::JSONSchema;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::JSONSchema

=head1 DESCRIPTION

Interface to queries involving JSON schemas.

=head1 METHODS

=head2 type

Chainable resultset that restricts the resultset to rows matching the specified C<type>.

=head2 name

Chainable resultset that restricts the resultset to rows matching the specified C<name>.

=head2 version

Chainable resultset that restricts the resultset to rows matching the specified C<version>.

=cut

foreach my $column (qw(type name version)) {
  Sub::Install::install_sub({
    as   => $column,
    code => sub ($self, $value) {
      $self->search({ $self->current_source_alias.'.'.$column => $value });
    },
  });
}

=head2 latest

Chainable resultset that restricts the resultset to the single row with the latest version.
(This won't make any sense when passed a resultset that queries for multiple types and/or
names, so don't do that.)

Does B<NOT> take deactivated status into account.

=cut

sub latest ($self) {
  $self->order_by({ -desc => 'version' })->rows(1);
}

=head2 with_description

Chainable resultset that adds the C<json_schema> C<description> to the results.

=cut

sub with_description ($self) {
  $self->add_columns({ description => \q{body->>'description'} });
}

=head2 with_created_user

Chainable resultset that adds columns C<created_user.name> and C<created_user.email> to the results.

=cut

sub with_created_user ($self) {
  $self
    ->search(undef, { join => 'created_user' })
    ->add_columns([map 'created_user.'.$_, qw(id name email) ]);
}

=head2 resource

Chainable resultset that restricts the resultset to the single row that matches
the indicated resource.  (Does B<not> fetch the indicated resource content -- you would need a
C<< ->column(...) >> for that.)

=cut

sub resource ($self, $type, $name, $version_or_latest) {
  my $me = $self->current_source_alias;
  my $rs = $self->search({ $me.'.type' => $type, $me.'.name' => $name });

  $rs = $version_or_latest eq 'latest'
    ? $rs->order_by({ -desc => 'version' })->rows(1)
    : $rs->search({ $me.'.version' => $version_or_latest });

  return $rs;
}

=head2 with_latest_flag

Chainable resultset that adds the C<latest> boolean flag to each result, indicating whether
that row is the latest of its type-name series (that is, whether it can be referenced as
C</json_schema/type/name/latest>).

The query will be closed off as a subselect (that additional chaining will SELECT FROM),
so it makes a difference whether you add things to the resultset before or after calling this
method.

=cut

sub with_latest_flag ($self) {
  my $me = $self->current_source_alias;

  # "Note that first_value, last_value, and nth_value consider only the rows within the
  # “window frame”, which by default contains the rows from the start of the partition
  # through the last peer of the current row."
  # therefore we sort in reverse, so latest comes first and is visible to all rows in the
  # window. see https://www.postgresql.org/docs/10/functions-window.html
  my $rs = $self
    ->add_columns([qw(id type name version deactivated)]) # make sure these columns are available
    ->search(undef, {
      '+select' => [{
        '' => \"first_value($me.id) over (partition by $me.type, $me.name order by $me.deactivated asc nulls first, version desc)",
        -as => 'last_row_id',
      }],
    })
    ->as_subselect_rs;

  # RT#132276: do not select columns that aren't there
  $rs = $rs->columns($self->{attrs}{columns}) if exists $self->{attrs}{columns};

  return $rs->add_columns({ latest => \"$me.id = last_row_id and $me.deactivated is null" });
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
