package Conch::Plugin::ClientVerification;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

=pod

=head1 NAME

Conch::Plugin::ClientVerification

=head1 DESCRIPTION

Checks the version of the client sending us a request, possibly rejecting it if it does not
meet our criteria.

For security reasons we do not specify the reason for the rejection in the error response,
but we will log it.

=cut

sub register ($self, $app, $config) {
    $app->hook(before_dispatch => sub ($c) {
        return if $c->req->url->path eq '/version';

        my $headers = $c->req->headers;
        my $user_agent = $headers->user_agent;

        if (my $conch_ui_version = $headers->header('X-Conch-UI')) {
            my ($major, $minor, $tiny, $rest) = $conch_ui_version =~ /^v(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?/;
            if (not $major or $major < 4) {
                $c->log->error('Conch UI too old: requires at least 4.x');
                return $c->status(403);
            }
        }
        elsif ($user_agent =~ /^conch shell/) {
            $c->log->error('Conch Shell too old');
            return $c->status(403);
        }
        elsif ($user_agent =~ /^Conch\/((\d+)\.(\d+)\.(\d+)) /) {
            my ($all, $major, $minor, $rest) = ($1, $2, $3, $4);
            if ($all eq '0.0.0') {
                $c->log->error('Conch Shell too old');
                return $c->status(403);
            }
            # TODO later: check $major, $minor for minimum compatible version.
        }
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
