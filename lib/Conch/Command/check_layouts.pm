package Conch::Command::check_layouts;

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

=pod

=head1 NAME

check_layouts - check for rack layout conflicts

=head1 SYNOPSIS

    check_layouts [long options...]

        --ws --workspace  workspace name
        --help            print usage message and exit

=cut

has description => 'Check for conflicts in existing rack layouts';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {

    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'check_layouts %o',
        [ 'workspace|ws=s', 'workspace name' ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    my $workspace_rs = $self->app->db_workspaces;
    $workspace_rs = $workspace_rs->search({ name => $opt->workspace }) if $opt->workspace;

    while (my $workspace = $workspace_rs->next) {
        my $rack_rs = $workspace->self_rs->associated_racks
            ->prefetch('datacenter_rack_role');

        while (my $rack = $rack_rs->next) {
            my %assigned;
            ++$assigned{$_} foreach $rack->self_rs->assigned_rack_units;

            my @assigned_rack_units = sort { $a <=> $b } keys %assigned;
            foreach my $rack_unit (@assigned_rack_units) {
                # check for slot overlaps
                if ($assigned{$rack_unit} > 1) {
                    print '# for workspace ', $workspace->id, ' (', $workspace->name,
                        '), datacenter_rack_id ', $rack->id, ' (', $rack->name, '), found ',
                        "$assigned{$rack_unit} assignees at rack_unit $rack_unit!\n";
                }
            }

            # check slot ranges against datacenter_rack_role.rack_size
            my $rack_size = $rack->datacenter_rack_role->rack_size;
            if (my @out_of_range = grep { $_ > $rack_size } @assigned_rack_units) {
                    print '# for workspace ', $workspace->id, ' (', $workspace->name,
                        '), datacenter_rack_id ', $rack->id, ' (', $rack->name, '), found ',
                        'assigned rack_units beyond the specified rack_size of ',
                        "$rack_size: @out_of_range!\n";
            }

            my $occupied_layout_rs = $rack->self_rs->related_resultset('datacenter_rack_layouts')
                ->search(
                    { 'device_location.device_id' => { '!=' => undef } },
                    { prefetch => [
                            'hardware_product',
                            { 'device_location' => { 'device' => 'hardware_product' } },
                        ] },
                );
            while (my $layout = $occupied_layout_rs->next) {
                # check for hardware_product_id mismatches.
                # this is also checked, sort of, in Conch::Validation::DeviceProductName
                if ($layout->hardware_product_id
                        ne $layout->device_location->device->hardware_product_id) {
                    print '# for workspace ', $workspace->id, ' (', $workspace->name,
                        '), datacenter_rack_id ', $rack->id, ' (', $rack->name, '), found ',
                        'occupied layout at rack_unit_start ', $layout->rack_unit_start,
                        ' with device with hardware_product_id ',
                        $layout->device_location->device->hardware_product_id, ' (',
                        $layout->device_location->device->hardware_product->alias, ') ',
                        'but layout expects hardware_product_id ',
                        $layout->hardware_product_id, ' (',
                        $layout->hardware_product->alias, ")!\n";
                }
            }
        }
    }
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
