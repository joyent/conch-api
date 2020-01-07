package Conch::Command::workspace_to_build;

=pod

=head1 NAME

workspace_to_build - convert workspace content to a build (one-off for v3 launch)

=head1 SYNOPSIS

    bin/conch workspace_to_build [long options...] <workspace name> [workspace name] ...

        -n --dry-run  dry-run (no changes are made)

        --help        print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use List::Util 'minstr';

has description => 'convert workspace content to a build';

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

    my @workspace_names = @ARGV;

    my $admin_id = $self->app->db_user_accounts->search({ email => 'ether@joyent.com' })->get_column('id')->single;
    my $joyent_org = $self->app->db_organizations->find({ name => 'Joyent' });
    my $samsung_org = $self->app->db_organizations->find({ name => 'Samsung' });
    my $dcops_org = $self->app->db_organizations->find({ name => 'DCOps' });

    my $spares = $self->app->db_builds
        ->prefetch([ qw(user_build_roles organization_build_roles) ])
        ->find({ name => 'spares' });
    if (not $spares) {
        $spares = $self->app->db_builds->create({
            name => 'spares',
            description => 'holding area for entities not yet part of an active build',
            user_build_roles => [{
                user_id => $admin_id,
                role => 'admin',
            }],
            organization_build_roles => [
                { organization_id => $joyent_org->id, role => 'ro' },
                { organization_id => $samsung_org->id, role => 'ro' },
                { organization_id => $dcops_org->id, role => 'rw' },
            ],
        });
    }
    else {
        $spares->add_to_organization_build_roles({ organization_id => $joyent_org->id, role => 'ro' }) if not grep $_->organization_id eq $joyent_org->id, $spares->organization_build_roles;
        $spares->add_to_organization_build_roles({ organization_id => $samsung_org->id, role => 'ro' }) if not grep $_->organization_id eq $samsung_org->id, $spares->organization_build_roles;
        $spares->add_to_organization_build_roles({ organization_id => $dcops_org->id, role => 'rw' }) if not grep $_->organization_id eq $dcops_org->id, $spares->organization_build_roles;
    }

    my $workspace_rs = $self->app->db_workspaces;

    foreach my $workspace_name (@workspace_names) {
        $self->app->schema->txn_do(sub {
            my $workspace = $workspace_rs->find({ name => $workspace_name });
            die 'cannot find workspace '.$workspace_name if not $workspace;

            my $build = $self->app->db_builds
                ->prefetch('organization_build_roles')
                ->find({ name => $workspace_name });

            if (not $build) {
                # find the earliest create date of each rack and device in the workspace and
                # use that as build.started
                my $device_created_rs = $workspace
                    ->related_resultset('workspace_racks')
                    ->related_resultset('rack')
                    ->related_resultset('device_locations')
                    ->related_resultset('device')
                    ->order_by('created')
                    ->rows(1)
                    ->hri
                    ->get_column('created');

                my $rack_created_rs = $workspace
                    ->related_resultset('workspace_racks')
                    ->related_resultset('rack')
                    ->order_by('created')
                    ->rows(1)
                    ->hri
                    ->get_column('created');

                $build = $self->app->db_builds->create({
                    name => $workspace_name,
                    description => $workspace->description,
                    started => minstr($device_created_rs->single, $rack_created_rs->single),
                    user_build_roles => [
                        { user_id => $admin_id, role => 'admin' },
                    ],
                    organization_build_roles => [
                        { organization_id => $joyent_org->id, role => 'ro' },
                        { organization_id => $samsung_org->id, role => 'ro' },
                        { organization_id => $dcops_org->id, role => 'rw' },
                    ],
                });
            }
            else {
                $build->add_to_organization_build_roles({ organization_id => $joyent_org->id, role => 'ro' }) if not grep $_->organization_id eq $joyent_org->id, $build->organization_build_roles;
                $build->add_to_organization_build_roles({ organization_id => $samsung_org->id, role => 'ro' }) if not grep $_->organization_id eq $samsung_org->id, $build->organization_build_roles;
                $build->add_to_organization_build_roles({ organization_id => $dcops_org->id, role => 'rw' }) if not grep $_->organization_id eq $dcops_org->id, $build->organization_build_roles;
            }

            # now put all of the workspace's racks into the build, if they weren't already in
            # another build
            $self->app->db_racks->search(
                    { 'rack.build_id' => undef, 'workspace.name' => $workspace_name },
                    { join => { workspace_racks => 'workspace' } },
                ) ->update({ build_id => $build->id });

            # now put all the racks's devices into the build, if they weren't already in
            # another build
            $self->app->db_devices->search(
                    { 'device.build_id' => undef, 'workspace.name' => $workspace_name },
                    { join => { device_location => { rack => { workspace_racks => 'workspace' } } } },
                )->update({ build_id => $build->id });
        });
    }

    # all remaining racks without a build are moved to the 'spares' build
    $self->app->db_racks->search({ build_id => undef })
        ->update({ build_id => $spares->id });
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
