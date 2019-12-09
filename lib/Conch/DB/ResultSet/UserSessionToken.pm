package Conch::DB::ResultSet::UserSessionToken;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::UserSessionToken

=head1 DESCRIPTION

Interface to queries against the 'user_session_token' table.

=head1 METHODS

=head2 expired

Chainable resultset to limit results to those that are expired.

=cut

sub expired ($self) {
    $self->search({ $self->current_source_alias.'.expires' => { '<=' => \'now()' } });
}

=head2 active

Chainable resultset to limit results to those that are not expired.

=cut

sub active ($self) { $self->unexpired }

=head2 unexpired

Chainable resultset to limit results to those that are not expired.

=cut

sub unexpired ($self) {
    $self->search({ $self->current_source_alias.'.expires' => { '>' => \'now()' } });
}

=head2 login_only

Chainable resultset to search for login tokens (created via the main C<POST /login> flow).

=cut

sub login_only ($self) {
    my $me = $self->current_source_alias;
    $self->search({ $me.'.name' => { '~' => 'login_jwt_[0-9_]+' } });
}

=head2 api_only

Chainable resultset to search for api tokens (NOT created via the main /login flow).

=cut

sub api_only ($self) {
    my $me = $self->current_source_alias;
    $self->search({ $me.'.name' => { '!~' => 'login_jwt_[0-9_]+' } });
}

=head2 expire

Update all matching rows by setting expires = now(). (Returns the number of rows updated.)

=cut

sub expire ($self) {
    $self->update({ expires => \'now()' });
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
