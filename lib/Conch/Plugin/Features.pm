package Conch::Plugin::Features;

use v5.26;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

=head1 NAME

Conch::Plugin::Features - Sets up a helper to access configured features

=head2 DESCRIPTION

Provides the helper sub 'feature' to the app and controllers:

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
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :