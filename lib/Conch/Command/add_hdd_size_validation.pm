package Conch::Command::add_hdd_size_validation;

=pod

=head1 NAME

add_hdd_size_validation - Add the 'hdd_size' validation to the Server validation plan

=head1 SYNOPSIS

    bin/conch add_hdd_size_validation [long options...]

        --help          print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'Add the hdd_size validation to the Server validation_plan';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'add_hdd_size_validation %o',
        [],
        [ 'help',  'print usage message and exit', { shortcircuit => 1 } ],
    );

    my $validation_plan = $self->app->db_validation_plans
        ->active
        ->find({ name => 'Conch v1 Legacy Plan: Server' });

    Conch::ValidationSystem->new(log => $self->app->log, schema => $self->app->schema)
        ->load_validations;

    my $hdd_size_validation = $self->app->db_validations
        ->active
        ->find({ module => 'Conch::Validation::HddSize' });

    $validation_plan->add_to_validation_plan_members({ validation => $hdd_size_validation });
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
