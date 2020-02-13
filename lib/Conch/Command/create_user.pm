package Conch::Command::create_user;

=pod

=head1 NAME

create_user - create a new user, optionally sending an email

=head1 SYNOPSIS

    bin/conch create_user --email <email> --name <name> [--password <password>] [--send-email]

  --email       The user's email address. Required.
  --name        The user's name. Required.
  --password    The user's temporary password. If not provided, one will be randomly generated.
  --send-email   Send a welcome email to the user (defaults to true)

      --help    print usage message and exit

=cut

use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Encode ();
use Email::Address::XS 1.01;
use Email::Valid;

has description => 'Create a new user';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;

    # decode command line arguments
    @ARGV = map Encode::decode('UTF-8', $_), @ARGV if grep /\P{ASCII}/, @ARGV;

    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $opt->usage
        'create_user %o',
        [ 'name|n=s',       'the user\'s name', { required => 1 } ],
        [ 'email|e=s',      'the user\'s email address', { required => 1 } ],
        [ 'password|p=s',   'the user password' ],
        [ 'send-email!',    'send email to user', { default => 1 } ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    if (not Email::Address::XS->parse($opt->email)->is_valid or not Email::Valid->address($opt->email)) {
        say 'cannot create user: email '.$opt->email.' is not a valid RFC822+RFC5322 address';
        return;
    }

    if ($self->app->db_user_accounts->active->search(\[ 'lower(email) = lower(?)', $opt->email ])->exists) {
        say 'cannot create user: email '.$opt->email.' already exists';
        return;
    }

    if ($self->app->db_user_accounts->active->search({ name => $opt->name })->exists) {
        say 'cannot create user: name '.$opt->name.' already exists';
        return;
    }

    my $password = $opt->password // $self->app->random_string;
    my $user = $self->app->db_user_accounts->create({
        name => $opt->name,
        email => $opt->email,
        password => $password, # will be hashed in constructor
    });
    my $user_id = $user->id;

    say 'created user ', $opt->name, ' with email ', $opt->email, ': user id ', $user_id;

    if ($opt->send_email) {
        say 'sending email to ', $opt->email, '...';
        $self->app->defaults(target_user => $user);
        $self->app->send_mail(
            template_file => 'new_user_account',
            From => 'noreply@conch.joyent.us',  # unfortunately we must hardcode this
            Subject => 'Welcome to Conch!',
            password => $password,
        );

        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
    }
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
