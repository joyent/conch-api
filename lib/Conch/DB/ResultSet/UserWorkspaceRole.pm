package Conch::DB::ResultSet::UserWorkspaceRole;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use Carp ();
use List::Util 'none';

=head1 NAME

Conch::DB::ResultSet::UserWorkspaceRole

=head1 DESCRIPTION

Interface to queries involving user/workspace permissions.

=head1 METHODS

=head2 user_has_permission

Returns a count of the number of specified user_workspace_role rows that grant the specified
permission level.  (Normally you'd treat this as a boolean check.)

=cut

sub user_has_permission {
    my ($self, $user_id, $permission) = @_;

    Carp::croak('permission must be one of: ro, rw, admin')
        if none { $permission eq $_ } qw(ro rw admin);

    $self->search({
        user_id => $user_id,
        role => { '>=' => \[ q{?::user_workspace_role_enum}, $permission ] },
    })->count;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
