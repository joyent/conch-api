package Conch::Plugin::AuthHelpers;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::JWT;

=pod

=head1 NAME

Conch::Plugin::AuthHelpers

=head1 DESCRIPTION

Contains all convenience handlers for authentication

=head1 HELPERS

These methods are made available on the C<$c> object (the invocant of all controller methods,
and therefore other helpers).

=cut

sub register ($self, $app, $config) {

=head2 is_system_admin

    return $c->status(403) if not $c->is_system_admin;

Verifies that the currently stashed user has the C<is_admin> flag set.

=cut

    $app->helper(is_system_admin => sub ($c) {
        $c->stash('user') && $c->stash('user')->is_admin;
    });


=head2 generate_jwt

Generates a session token for the specified user and stores it in the database.
Returns the new row and the JWT.

C<expires> is an epoch time.

=cut

    $app->helper(generate_jwt => sub ($c, $user_id, $expires_abs, $token_name) {
        return $c->status(409, { error => 'name "'.$token_name.'" is already in use' })
            if $c->db_user_session_tokens
                ->search({ user_id => $user_id, name => $token_name })->exists;

        my $session_token = $c->db_user_session_tokens->create({
            user_id => $user_id,
            name => $token_name,
            expires => \[ q{to_timestamp(?)::timestamptz}, $expires_abs ],
        });

        return ($session_token, $c->generate_jwt_from_token($session_token));
    });

=head2 generate_jwt_from_token

Given a session token, generate a JWT for it.

=cut

    $app->helper(generate_jwt_from_token => sub ($c, $session_token) {
        return Mojo::JWT->new(
            claims => { user_id => $session_token->user_id, token_id => $session_token->id },
            secret => $c->app->secrets->[0],
            expires => $session_token->expires->epoch,
        )->encode;
    });
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
