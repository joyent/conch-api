package Conch::DB::ResultSet::UserWorkspaceRole;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';
use Carp ();
use List::Util 'none';

=head1 NAME

Conch::DB::ResultSet::UserWorkspaceRole

=head1 DESCRIPTION

Interface to queries involving user/workspace roles.

=head1 METHODS

=head2 with_role

Constrains the resultset to those user_workspace_role rows that grants (at least) the specified
role.

=cut

sub with_role ($self, $role) {
    Carp::croak('role must be one of: ro, rw, admin')
        if none { $role eq $_ } qw(ro rw admin);

    $self->search({ role => { '>=' => \[ '?::user_workspace_role_enum', $role ] } });
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
