package Conch::Command::force_password_change;

=pod

=head1 NAME

force_password_change - force a user or users to change their password

=head1 SYNOPSIS

    bin/conch force_password_change [long options...]

        -n --dry-run    dry-run (no changes are made)
        --email         modify this user, by email (can be used more than once)

        --help          print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'force a user (or by default, all users) to change their password';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'clean_roles %o',
        [ 'dry-run|n',      'dry-run (no changes are made)' ],
        [ 'email=s@',       'email address of user to be modified (can be used more than once)' ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    my $users_rs = $self->app->db_user_accounts->active->search({ force_password_change => 0 });

    if (my $emails = $opt->email) {
        my @emails = $emails->@*;
        $users_rs = $users_rs->search(\[ 'lower(email) IN ('.join(', ', ('lower(?)')x@emails).')', @emails ]);
    }

    my $token_rs = $users_rs->related_resultset('user_session_tokens')->unexpired;

    if ($opt->dry_run) {
        say $users_rs->count, ' users would be updated. ', $token_rs->count, ' session tokens would be expired.';
        exit 0;
    }

    my $user_count = $users_rs->update({ force_password_change => 1 });
    my $token_count = $token_rs->update({ expires => \'now()' });
    say 0+$user_count, ' users updated; ', 0+$token_count, ' session tokens expired.';
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
