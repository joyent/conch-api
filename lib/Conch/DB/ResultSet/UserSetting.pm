package Conch::DB::ResultSet::UserSetting;
use v5.20;
use warnings;
use parent 'DBIx::Class::ResultSet';

=head1 DESCRIPTION

Interface to queries against the 'user_setting' table.

=head2 active

Chainable resultset to limit results to those that aren't deactivated.
TODO: move to a role 'Deactivatable'

=cut

sub active {
    my $self = shift;

    $self->search({ deactivated => undef });
}

=head2 deactivate

Update all matching rows by setting deactivated = NOW().
TODO: move to a role 'Deactivatable'

=cut

sub deactivate {
    my $self = shift;

    $self->update({ deactivated => \'NOW()' });
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
