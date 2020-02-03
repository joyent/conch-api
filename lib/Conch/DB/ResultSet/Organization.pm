package Conch::DB::ResultSet::Organization;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::Organization

=head1 DESCRIPTION

Interface to queries involving organizations.

=head1 METHODS

=head2 admins

All the 'admin' users for the provided organization(s). Pass a true argument to also include all
system admin users in the result.

=cut

sub admins ($self, $include_sysadmins = undef) {
    my $rs = $self->search_related('user_organization_roles', { role => 'admin' })
        ->related_resultset('user_account');

    $rs = $rs->union_all($self->result_source->schema->resultset('user_account')->search_rs({ is_admin => 1 }))
        if $include_sysadmins;

    return $rs
        ->active
        ->distinct
        ->order_by('user_account.name');
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
