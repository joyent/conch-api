package Conch::Command::create_token;

=pod

=head1 NAME

create_token - create a new api token

=head1 SYNOPSIS

    bin/conch create_token [long options...]

        --name    required; the name to give the token
        --email   required; the user account for which to create the token

        --help    print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'Create a new application token';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'create_token %o',
        [ 'name|n=s', 'the name to give the token', { required => 1 } ],
        [ 'email|e=s', 'the user account for which to create the token', { required => 1 } ],
        [],
        [ 'help', 'print usage message and exit', { shortcircuit => 1 } ],
    );

    my $user = $self->app->db_user_accounts->active->find_by_email($opt->email);
    die 'cannot find user with email ', $opt->email if not $user;

    my $expires_abs = time + (($self->app->config('authentication')//{})->{custom_token_expiry} // 86400*365*5);
    my ($token, $jwt) = $self->app->generate_jwt($user->id, $expires_abs, $opt->name);
    say $jwt;
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
