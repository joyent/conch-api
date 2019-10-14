package Conch::DB::ResultSet::UserAccount;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::UserAccount

=head1 DESCRIPTION

Interface to queries against the C<user_account> table.

=head2 find_by_email

Queries for user by (case-insensitive) email address.

If more than one user is found, we return the one created most recently.

If you want to search only for B<active> users, apply the C<< ->active >> resultset to the
caller first.

=cut

sub find_by_email ($self, $email) {
    return $self->search_by_email($email)->one_row;
}

=head2 search_by_email

Just the resultset for L</find_by_email>.

=cut

sub search_by_email ($self, $email) {
    return $self
        ->search(\[ 'lower(email) = lower(?)', $email ])
        ->order_by({ -desc => 'created' })
        ->rows(1);
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
