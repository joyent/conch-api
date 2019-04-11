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

=head2 expired

Chainable resultset to limit results to those that are expired.

=cut

sub expired ($self) {
    $self->search({ $self->current_source_alias.'.expires' => { '<=' => \'now()' } });
}

=head2 active

Chainable resultset to limit results to session tokens that are not expired.

=cut

sub active ($self) { $self->unexpired }

=head2 unexpired

Chainable resultset to limit results to those that aren't expired.

=cut

sub unexpired ($self) {
    $self->search({ $self->current_source_alias.'.expires' => { '>' => \'now()' } });
}

=head2 search_for_user_token

Chainable resultset to search for matching tokens.
This does *not* check the expires field: chain with 'unexpired' if this is desired.

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

=head2 login_only

Chainable resultset to search for login tokens (created via the main /login flow).

=cut

sub login_only ($self) {
    $self->search({ name => { '-similar to' => 'login_jwt_[0-9_]+' } });
}

=head2 expire

Update all matching rows by setting expires = now(). (Returns the number of rows updated.)

=cut

sub expire ($self) {
    $self->update({ expires => \'now()' });
}

=head2 generate_for_user

Generates a session token for the user and stores it in the database.
'expires' is an epoch time.

Returns the db row inserted, and the token string that we generated.

=cut

sub generate_for_user ($self, $user_id, $expires, $name) {
    warn 'user_id is null' if not $user_id;
    warn 'expires is not set' if not $expires;

    my $token = Session::Token->new->get;

    my $row = $self->create({
        user_id => $user_id,
        name => $name,
        token_hash => \[ q{digest(?, 'sha256')}, $token ],
        expires => \[ q{to_timestamp(?)::timestamptz}, $expires ],
    });

    return ($row, $token);
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
