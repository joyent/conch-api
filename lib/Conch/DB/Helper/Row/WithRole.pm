package Conch::DB::Helper::Row::WithRole;
use v5.26;
use warnings;

use parent 'DBIx::Class::Core';

=head1 NAME

Conch::DB::Helper::Row::WithRole

=head1 DESCRIPTION

A component for L<Conch::DB::Result> classes for database tables with a C<role>
column, to provide common functionality.

=head1 USAGE

    __PACKAGE__->load_components('+Conch::DB::Helper::Row::WithRole');

=head1 METHODS

=head2 role_cmp

Acts like the C<cmp> operator, returning -1, 0 or 1 depending on whether the first role is less
than, the same as, or greater than the second role.

If only one role argument is passed, the role in the current row is compared to the passed-in
role.

Accepts undef for one or both roles, which always compare as less than a defined role.

=cut

sub role_cmp {
    my $self = shift;

    state $role_to_int = do {
        my $i = 0;
        +{ map +($_ => ++$i), $self->column_info('role')->{extra}{list}->@* };
    };

    my ($role1, $role2) =
        @_ == 2 ? (shift, shift)
      : @_ == 1 ? ($self->role, shift)
      : die 'insufficient arguments';

    (defined $role1 ? $role_to_int->{$role1} : 0) <=> (defined $role2 ? $role_to_int->{$role2} : 0);
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
