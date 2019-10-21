package Conch::Command::fix_usernames;

=pod

=head1 NAME

fix_usernames - fixes old usernames in the database

=head1 SYNOPSIS

    bin/conch fix_usernames [long options...]

        -n --dry-run  dry-run (no changes are made)

        --help        print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'fixes Joyent usernames so they are not the same as the email';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'clean_roles %o',
        [ 'dry-run|n',      'dry-run (no changes are made)' ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    $self->app->schema->txn_do(sub {
        my $user_rs = $self->app->db_user_accounts
            ->active
            ->search({ name => { '=' => \'email' } })
            ->search({ email => { -like => '%@joyent.com%' } });

        print STDERR '# examining '.$user_rs->count.' users...'."\n";

        while (my $user = $user_rs->next) {
            print STDERR '# considering name='.$user->name.', email='.$user->email."\n";
            my ($userid, $host) = split(/@/, $user->name, 2);
            next if not $userid;
            next if $userid !~ /\./;
            next if $userid =~ /\+/;

            my ($first, $last) = split(/\./, $userid, 2);
            $first = ucfirst $first;
            $last = ucfirst $last;

            print '# name will become '.$first.' '.$last."\n";
            next if $opt->dry_run;

            $user->update({ name => $first.' '.$last });
        }
    });
}

1;
