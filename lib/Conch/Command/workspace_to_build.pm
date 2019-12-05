package Conch::Command::workspace_to_build;

=pod

=head1 NAME

workspace_to_build - convert workspace content to a build

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
    my $company_org = $self->app->db_organizations->find_or_create({
        name => 'Joyent',
        description => 'Joyent employees',
        user_organization_roles => [ { user_id => $admin_id, role => 'admin' } ],
    });
    my $dcops_org = $self->app->db_organizations->find_or_create({
        name => 'DCOps',
        description => 'Datacenter Operations personnnel',
        user_organization_roles => [ { user_id => $admin_id, role => 'admin' } ],
    });

    my $spares = $self->app->db_builds->find_or_create({
        name => 'spares',
        description => 'holding area for entities not yet part of an active build',
        user_build_roles => [{
            user_id => $admin_id,
            role => 'admin',
        }],
        organization_build_roles => [{
            organization_id => $company_org->id,
            role => 'ro',
        }],
        organization_build_roles => [{
            organization_id => $dcops_org->id,
            role => 'rw',
        }],
    });

    foreach my $workspace_name (@workspace_names) {
        $self->app->schema->txn_do(sub {
            my $workspace = $self->app->db_workspaces->find({ name => $workspace_name });
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

                $build = $self->app->db_builds->create({
                    name => $workspace_name,
                    description => $workspace->description,
                    started => minstr($device_created_rs->single, $rack_created_rs->single),
                    user_build_roles => [{
                        user_id => $admin_id,
                        role => 'admin',
                    }],
                    organization_build_roles => [{
                        organization_id => $company_org->id,
                        role => 'ro',
                    }],
                    organization_build_roles => [{
                        organization_id => $dcops_org->id,
                        role => 'rw',
                    }],
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
