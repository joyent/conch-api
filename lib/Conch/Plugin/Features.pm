package Conch::Plugin::Features;

use v5.26;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

=pod

=head1 NAME

Conch::Plugin::Features - Sets up a helper to access configured features

=head1 METHODS

=head2 register

Sets up the helpers.

=head1 HELPERS

These methods are made available on the C<$c> object (the invocant of all controller methods,
and therefore other helpers).

=head2 feature

Checks if a given feature name is enabled.

    if ($c->feature('rollbar') { ... }

=cut

sub register ($self, $app, $config) {
    $app->helper(feature => sub ($c, $feature_name) {
        state $features = $config->{features} // {};
        return $features->{$feature_name};
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
