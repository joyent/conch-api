package Conch::DB::ResultSet::UserAccount;
use v5.20;
use warnings;
use parent 'DBIx::Class::ResultSet';

use Conch::UUID 'is_uuid';

=head1 DESCRIPTION

Interface to queries against the 'user_account' table.

=head2 create

This method is built in to all resultsets.  In Conch::DB::Result::UserAccount we have overrides
allowing us to receive the 'password' key, which we hash into 'password_hash'.

    $c->schema->resultset('UserAccount') or $c->db_user_accounts
    ->create({
        name => ...,        # required, but usually the same as email :/
        email => ...,       # required
        password => ...,    # required, if password_hash not provided
    });

=cut

=head2 lookup_by_id

=cut

sub lookup_by_id {
    my ($self, $user_id) = @_;
    return if not is_uuid($user_id);    # avoid pg exception "invalid input syntax for uuid"
    $self->find({ id => $user_id });
}

=head2 lookup_by_email

=cut

sub lookup_by_email {
    my ($self, $email) = @_;
    $self->find({ email => $email });
}

=head2 lookup_by_name

=cut

sub lookup_by_name {
    my ($self, $name) = @_;
    $self->find({ name => $name });
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
