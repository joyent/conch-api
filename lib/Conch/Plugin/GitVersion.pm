package Conch::Plugin::GitVersion;

use v5.26;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use IPC::System::Simple 'capturex';

=pod

=head1 NAME

Conch::Plugin::GitVersion

=head1 DESCRIPTION

Mojo plugin registering the git version tag and hash for the repository

=head1 HELPERS

=cut

sub register ($self, $app, $config) {

=head2 version_tag

Provides a string that uniquely describes the version and commit of the currently-running code.

=cut

    chomp(my $git_tag = capturex(qw(git describe --always --long)));
    $app->log->fatal('git error') and die 'git error' if not $git_tag;
    $app->helper(version_tag => sub ($) { $git_tag });

=head2 version_tag

Provides the exact git SHA of the currently-running code.

=cut

    chomp(my $git_hash = capturex(qw(git rev-parse HEAD)));
    $app->log->fatal('git error') and die 'git error' if not $git_hash;
    $app->helper(version_hash => sub ($) { $git_hash });
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
