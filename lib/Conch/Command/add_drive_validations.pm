package Conch::Command::add_drive_validations;

=pod

=head1 NAME

add_drive_validations - A one-time command to add new drive validations to the Server validation plan.

=head1 SYNOPSIS

    add_drive_validations [long options...]

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'add new drive validations to the Server validation plan';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {

    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'add_drive_validations %o',
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    # deactivating old validations whose versions are incrementing
    $self->app->db_validations->search({
        name => { -in => [ qw(disk_smart_status sas_ssd_num) ] },
    })->deactivate;

    $self->app->log->info('Adding new drive validation rows...');

    # make sure all updates have been applied for existing validations, and create new
    # validation rows
    Conch::ValidationSystem->new(
        log => $self->app->log,
        schema => $self->app->schema,
    )->load_validations;

    $self->app->log->info('Adding new drive validations to Server plan...');

    my $validation_plan = $self->app->db_validation_plans->find({ name => 'Conch v1 Legacy Plan: Server' });
    die 'Failed to find validation plan in database' if not $validation_plan;

    my @new_drive_validations = $self->app->db_validations->active->search(
        { name => { -in => [ qw(disk_smart_status sas_ssd_num sata_hdd_num sata_ssd_num nvme_ssd_num raid_lun_num) ] } });
    die 'Failed to find new drive validations (got '.scalar(@new_drive_validations).')' if @new_drive_validations != 6;

    $validation_plan->create_related('validation_plan_members',
            { validation_plan_id => $validation_plan->id, validation_id => $_->id })
        foreach @new_drive_validations;

    $self->app->log->info('Done adding new drive validations to Server plan');
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
