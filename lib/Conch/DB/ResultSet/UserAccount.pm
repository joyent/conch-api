package Conch::DB::ResultSet::UserAccount;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';
use Conch::UUID 'is_uuid';
use Email::Valid;

=head1 NAME

Conch::DB::ResultSet::UserAccount

=head1 DESCRIPTION

Interface to queries against the C<user_account> table.

=head2 create

This method is built in to all resultsets.  In Conch::DB::Result::UserAccount we have overrides
allowing us to receive the C<password> key, which we hash into C<password_hash>.

    $schema->resultset('user_account') or $c->db_user_accounts
      ->create({
        name => ...,        # required, but usually the same as email :/
        email => ...,       # required
        password => ...,    # required, if password_hash not provided
      });

=cut

=head2 update

This method is built in to all resultsets.  In Conch::DB::Result::UserAccount we have overrides
allowing us to receive the C<password> key, which we hash into C<password_hash>.

    $schema->resultset('user_account') or $c->db_user_accounts
      ->update({
        password => ...,
        ... possibly other things
      });

=cut

=head2 lookup_by_email

Queries for user by (case-insensitive) email address.

If more than one user is found, we return the one created most recently, and a warning will be
logged (via L<DBIx::Class::ResultSet/single>).

If you want to search only for *active* users, apply the C<< ->active >> resultset to the
caller first.

=cut

sub lookup_by_email ($self, $email) {
    return $self
        ->search(\[ 'lower(email) = lower(?)', $email ])
        ->order_by({ -desc => 'created' })
        ->rows(1)
        ->one_row;
}

=head2 lookup_by_id_or_email

Queries for user by (case-insensitive) email if string matches C</^email=/>, otherwise queries
by user id.

If more than one user is found, we return the one created most recently, and a warning will be
logged (via L<DBIx::Class::ResultSet/single>).

If you want to search only for *active* users, apply the C<< ->active >> resultset to the
caller first.

=cut

sub lookup_by_id_or_email ($self, $identifier) {
    if ($identifier =~ /^email=/) {
        return $self
            ->search(\[ 'lower(email) = lower(?)', $' ])
            ->order_by({ -desc => 'created' })
            ->rows(1)
            ->one_row;
    }

    # avoid pg exception "invalid input syntax for uuid"
    if (is_uuid($identifier)) {
        return $self->find($identifier);
    }

    warn 'invalid identifier format for '.$identifier
        if not Email::Valid->address($identifier);
    return;
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
