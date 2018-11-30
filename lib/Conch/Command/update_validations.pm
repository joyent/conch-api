package Conch::Command::update_validations;

=pod

=head1 NAME

update_validations - Update validation entries in the database to match Conch::Validation::* classes.

=head1 SYNOPSIS

    update_validations [long options...]

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Mojo::JSON 'from_json', 'encode_json';

has description => 'update database validation entries to match Conch::Validation::* classes';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {

    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'update_validations %o',
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    Conch::ValidationSystem->new(
        log => Mojo::Log->new(handle => \*STDOUT),
        schema => $self->app->schema,
    )->load_validations;
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
