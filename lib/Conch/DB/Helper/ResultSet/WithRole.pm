package Conch::DB::Helper::ResultSet::WithRole;
use v5.26;
use warnings;

use experimental 'signatures';
use Carp ();
use List::Util 'none';

=head1 NAME

Conch::DB::Helper::ResultSet::WithRole

=head1 DESCRIPTION

A component for L<Conch::DB::ResultSet> classes for database tables with a C<role>
column, to provide common query functionality.

=head1 USAGE

    __PACKAGE__->load_components('+Conch::DB::Helper::ResultSet::WithRole');

=head1 METHODS

=head2 with_role

Constrains the resultset to those rows that grants (at least) the specified role.

=cut

sub with_role ($self, $role) {
    return $self if $role eq 'none';

    Carp::croak('role must be one of: ro, rw, admin')
        if !$ENV{MOJO_MODE} and none { $role eq $_ } qw(ro rw admin);

    Carp::croak($self->result_source->result_class->table,
        ' does not have a \'role\' column')
    if !$ENV{MOJO_MODE} and not $self->result_source->has_column('role');

    return $self->search if $role eq 'ro';
    $self->search({ $self->current_source_alias.'.role' => { '>=' => $role } });
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
