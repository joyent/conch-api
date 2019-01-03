package Conch::DB::ResultSet::UserSessionToken;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';
use Session::Token;

=head1 NAME

Conch::DB::ResultSet::UserSessionToken

=head1 DESCRIPTION

Interface to queries against the 'user_session_token' table.

=cut

=head2 expired

Chainable resultset to limit results to session tokens that are expired.

=cut

sub expired ($self) {
    $self->search({ expires => { '<=' => \'now()' } });
}

=head2 active

Chainable resultset to limit results to session tokens that are not expired.

=cut

sub active ($self) {
    $self->search({ expires => { '>' => \'now()' } });
}

=head2 search_for_user_token

Chainable resultset to search for matching tokens.
This does *not* check the expires field: chain with 'active' if this is desired.

=cut

sub search_for_user_token ($self, $user_id, $token) {
    warn 'user_id is null' if not $user_id;
    warn 'token is null' if not $token;

    # note: returns a resultset, not a result!
    $self->search({
        user_id => $user_id,
        token_hash => { '=' => \[ q{digest(?, 'sha256')}, $token ] },
    });
}

=head2 expire

Mark the matching token(s) as expired. (Returns the number of rows updated.)

=cut

sub expire ($self) {
    $self->update({ expires => \'now()' });
}

=head2 generate_for_user

Generates a session token for the user and stores it in the database.
Returns the token that was generated.

=cut

sub generate_for_user ($self, $user_id, $expires) {
    warn 'user_id is null' if not $user_id;
    warn 'expires is not set' if not $expires;

    my $token = Session::Token->new->get;

    $self->create({
        user_id => $user_id,
        token_hash => \[ q{digest(?, 'sha256')}, $token ],
        expires => \[ q{to_timestamp(?)::timestamptz}, $expires ],
    });

    return $token;
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
