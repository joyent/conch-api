package Conch::Plugin::GitVersion;

use v5.26;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use IPC::System::Simple 'capturex';

=pod

=head1 NAME

Conch::Plugin::GitVersion

=head1 DESCRIPTION

Mojo plugin registering the git version tag and hash for the repository

=head1 METHODS

=head2 register

Register C<version_tag> and C<version_hash>.

=cut

sub register ($self, $app, $config) {
    chomp(my $git_tag = capturex(qw(git describe --always --long)));
    $app->log->fatal('git error') and die 'git error' if not $git_tag;

    chomp(my $git_hash = capturex(qw(git rev-parse HEAD)));
    $app->log->fatal('git error') and die 'git error' if not $git_hash;

    $app->helper(version_tag => sub ($) { $git_tag });
    $app->helper(version_hash => sub ($) { $git_hash });
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
