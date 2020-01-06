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

    my $spares = $self->app->db_builds->find_or_create({
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

    my $workspace_rs = $self->app->db_workspaces;

    foreach my $workspace_name (@workspace_names) {
        $self->app->schema->txn_do(sub {
            my $workspace = $workspace_rs->find({ name => $workspace_name });
            die 'cannot find workspace '.$workspace_name if not $workspace;

            my $build = $self->app->db_builds->find({ name => $workspace_name });

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

                # some of these may be collapsed into organization_build_role entries
                # later on, but for now, just copy all user_workspace_role -> user_build_role
                my @user_roles = $self->app->db_workspaces
                    ->and_workspaces_above($workspace->id)
                    ->search_related('user_workspace_roles', { user_id => { '!=' => $admin_id } })
                    ->columns([ 'user_id', { role => { max => 'role' } } ])
                    ->group_by(['user_id'])
                    ->hri
                    ->all;

                $build = $self->app->db_builds->create({
                    name => $workspace_name,
                    description => $workspace->description,
                    started => minstr($device_created_rs->single, $rack_created_rs->single),
                    user_build_roles => [
                        {
                            user_id => $admin_id,
                            role => 'admin',
                        },
                        @user_roles,
                    ],
                    organization_build_roles => [
                        { organization_id => $joyent_org->id, role => 'ro' },
                        { organization_id => $samsung_org->id, role => 'ro' },
                        { organization_id => $dcops_org->id, role => 'rw' },
                    ],
                });
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
