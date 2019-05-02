package Conch::Command::update_validations_release_224;

=pod

=head1 NAME

update_validations_release_224 - A one-time command to update validations to the Server validation plan for release 2.24.

=head1 SYNOPSIS

    bin/conch update_validations_release_224 [long options...]

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'add new validations to the Server validation plan';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'update_validations_release_224 %o',
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    $self->app->schema->txn_do(sub ($app) {
        # deactivate old validations whose versions are incrementing
        $app->db_validations->active->search({ name => 'dimm_count' })->deactivate;

        $app->log->info('Adding new validation rows...');

        # make sure all updates have been applied for existing validations, and create new
        # validation rows
        Conch::ValidationSystem->new(
            log => $app->log,
            schema => $app->schema,
        )->load_validations;

        $app->log->info('Adding new validations to Server plan...');

        my $validation_plan = $app->db_validation_plans->find({ name => 'Conch v1 Legacy Plan: Server' });
        die 'Failed to find validation plan in database' if not $validation_plan;

        my @new_validations = $app->db_validations->active->search(
            { name => { -in => [ qw(dimm_count) ] } });
        die 'Failed to find new validations (got '.scalar(@new_validations).')' if @new_validations != 1;

        $validation_plan->create_related('validation_plan_members',
                { validation_plan_id => $validation_plan->id, validation_id => $_->id })
            foreach @new_validations;

        $app->log->info('Done adding new validations to Server plan');

    }, $self->app);
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
