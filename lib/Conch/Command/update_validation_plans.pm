package Conch::Command::update_validation_plans;

=pod

=head1 NAME

update_validation_plans - Utility to bring validations and validation_plans up to date

=head1 SYNOPSIS

    bin/conch update_validation_plans [long options...]

        --update_all    update all plans to use the new version of this validation

        --help          print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Try::Tiny;

has description => 'bring validation_plans up to date with new versions of all validations';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'update_validation_plans %o',
        [ 'update_all', 'update all active validation plans to use the latest validation versions (default behaviour)', { default => 1 } ],
        [],
        [ 'help',  'print usage message and exit', { shortcircuit => 1 } ],
    );

    if (not $opt->update_all) {
        # this is the only supported mode, for now
        die '--update-all not set. no supported fallback behaviour.';
    }

    my $schema = $self->app->schema;
    try {
        # all work will be performed in a transaction, so we can bail out if something surprising
        # happens and there will be no ill effects.
        $schema->txn_do(sub {
            Conch::ValidationSystem->new(
                log => $self->app->log,
                schema => $schema,
            )->update_validation_plans;
        });
    }
    catch {
        $self->log->fatal($_);
        die $_;
    };
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
