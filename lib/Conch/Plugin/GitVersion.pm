package Conch::Plugin::GitVersion;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Capture::Tiny 'capture';

=pod

=head1 NAME

Conch::Plugin::GitVersion

=head1 DESCRIPTION

Mojo plugin registering the git version tag and hash for the repository

=head1 METHODS

=head2 register

Register C<version_tag> and C<version_hash>.

=cut

sub register ($self, $app, $conf) {

    my ($git_tag, $git_tag_stderr, undef) = capture {
        system(qw(git describe --always --long));
    };
    chomp($git_tag ||= 'unknown');
    $app->log->fatal('git error: ' . $git_tag_stderr) and die
        if $git_tag_stderr;

    my ($git_hash, $git_hash_stderr, undef) = capture {
        system(qw(git rev-parse HEAD));
    };
    chomp($git_hash ||= 'unknown');
    $app->log->fatal('git error: ' . $git_hash_stderr) and die
        if $git_hash_stderr;

    $app->helper(
        version_tag  => sub { $git_tag }
    );
    $app->helper(
        version_hash => sub { $git_hash }
    );
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
