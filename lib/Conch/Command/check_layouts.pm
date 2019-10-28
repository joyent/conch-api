package Conch::Command::check_layouts;

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

=pod

=head1 NAME

check_layouts - check for rack layout conflicts

=head1 SYNOPSIS

    bin/conch check_layouts [long options...]

        --ws --build      build name

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
        [ 'build|b=s', 'build name to limit search to' ],
        [],
        [ 'help',      'print usage message and exit', { shortcircuit => 1 } ],
    );

        my $rack_rs = $self->app->db_racks->prefetch([ qw(rack_role build) ]);
        $rack_rs = $rack_rs->search({ 'build.name' => $opt->build }, { join => 'build' }) if $opt->build;

        while (my $rack = $rack_rs->next) {
            my %assigned;
            ++$assigned{$_} foreach $rack->self_rs->assigned_rack_units;

            my @assigned_rack_units = sort { $a <=> $b } keys %assigned;
            foreach my $rack_unit (@assigned_rack_units) {
                # check for slot overlaps
                if ($assigned{$rack_unit} > 1) {
                    print '# for ',
                        ($rack->build_id ? ('build ', $rack->build_id, ' (', $rack->build->name, '), ') : ()),
                        'rack_id ', $rack->id, ' (', $rack->name, '), found ',
                        "$assigned{$rack_unit} assignees at rack_unit $rack_unit!\n";
                }
            }

            # check slot ranges against rack_role.rack_size
            my $rack_size = $rack->rack_role->rack_size;
            if (my @out_of_range = grep $_ > $rack_size, @assigned_rack_units) {
                    print '# for ',
                        ($rack->build_id ? ('build ', $rack->build_id, ' (', $rack->build->name, '), ') : ()),
                        'rack_id ', $rack->id, ' (', $rack->name, '), found ',
                        'assigned rack_units beyond the specified rack_size of ',
                        "$rack_size: @out_of_range!\n";
            }

            my $occupied_layout_rs = $rack->search_related('rack_layouts',
                    { 'device_location.device_id' => { '!=' => undef } },
                    { prefetch => [
                            'hardware_product',
                            { device_location => { device => 'hardware_product' } },
                        ] },
                );
            while (my $layout = $occupied_layout_rs->next) {
                # check for hardware_product_id mismatches.
                # this is also checked, sort of, in Conch::Validation::DeviceProductName
                if ($layout->hardware_product_id
                        ne $layout->device_location->device->hardware_product_id) {
                    print '# for ',
                        ($rack->build_id ? ('build ', $rack->build_id, ' (', $rack->build->name, '), ') : ()),
                        'rack_id ', $rack->id, ' (', $rack->name, '), found ',
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
