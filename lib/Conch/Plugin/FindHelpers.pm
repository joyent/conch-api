package Conch::Plugin::FindHelpers;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Conch::UUID 'is_uuid';
use Email::Valid;

=pod

=head1 NAME

Conch::Plugin::FindHelpers

=head1 DESCRIPTION

Common methods for looking up various data in the database and saving it to the stash, or
generating error responses as appropriate.

These are suitable to be used in C<under> calls in various routes, or directly by a controller
method.

=head1 HELPERS

=cut

sub register ($self, $app, $config) {

=head2 find_user

Validates the provided user_id or email address (prefaced with 'email='), and stashes the
corresponding user row in C<target_user>.

=cut

    $app->helper(find_user => sub ($c, $user_param) {
        return $c->status(400, { error => 'invalid identifier format for '.$user_param })
            if not is_uuid($user_param)
                and not ($user_param =~ /^email\=/ and Email::Valid->address($'));

        my $user_rs = $c->db_user_accounts;

        # when deactivating users or removing users from a workspace, we want to find
        # already-deactivated users too.
        $user_rs = $user_rs->active if $c->req->method ne 'DELETE';

        $c->app->log->debug('looking up user '.$user_param);
        my $user = $user_rs->lookup_by_id_or_email($user_param);

        return $c->status(404) if not $user;

        $c->stash('target_user', $user);
        return $user;
    });

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
