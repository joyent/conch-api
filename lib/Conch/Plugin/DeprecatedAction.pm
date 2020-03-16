package Conch::Plugin::DeprecatedAction;

use v5.26;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

=pod

=head1 NAME

Conch::Plugin::DeprecationAction

=head1 DESCRIPTION

Mojo plugin to detect and report the usage of deprecated controller actions.

=head1 METHODS

=head2 register

Sets up the hooks.

=head1 HOOKS

=head2 after_dispatch

Sets the C<X-Deprecated> header in the response.

Also sends a message to Rollbar when a deprecated action is invoked, if the
C<report_deprecated_actions> feature is enabled.

=cut

sub register ($self, $app, $config) {
    $app->hook(after_dispatch => sub ($c) {
        if (my $deprecated = $c->stash('deprecated')) {
            $c->res->headers->add('X-Deprecated', 'this endpoint is deprecated and will be removed in api '.$deprecated);

            # do this after the response has been sent
            $c->on(finish => sub ($c) {
                $c->send_message_to_rollbar('info', $deprecated,
                    { context => ($c->stash('controller')//'').'#'.($c->stash('action')//'') });
            })
            if $c->feature('rollbar') and $c->feature('report_deprecated_actions');
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
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
