package Conch::Command::check_validation_plans;

=pod

=head1 NAME

check_validation_plans - Utility to check all validations and plans are up to date

=head1 SYNOPSIS

    bin/conch check_validation_plans [long options...]

        --help          print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'check all validations and validation plans';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'check_validation_plans %o',
        [],
        [ 'help',  'print usage message and exit', { shortcircuit => 1 } ],
    );

    # any issues found go to stderr
    Conch::ValidationSystem->new(log => Conch::Log->new, schema => $self->app->ro_schema)
        ->check_validation_plans;
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
