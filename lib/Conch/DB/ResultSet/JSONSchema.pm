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
