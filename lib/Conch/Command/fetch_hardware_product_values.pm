package Conch::Command::fetch_hardware_product_values;

=pod

=head1 NAME

fetch_hardware_product_specifiations - dump a CSV of all hardware_product.specification values

=head1 SYNOPSIS

    bin/conch fetch_hardware_product_values [long options...]

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Text::CSV_XS;
use List::Util 'any';
use Mojo::JSON qw(from_json to_json);
use Mojo::JSON::Pointer;

has description => '...';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'fetch_hardware_product_values %o',
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    my $csv = Text::CSV_XS->new({ binary => 1, eol => $/ });
    my $fh = \*STDOUT;

    my $rs = $self->app->db_hardware_products
        ->prefetch('hardware_product_profile')
        ->active
        ->hri;

    my @drop_hw_columns = qw(created updated deactivated specification);
    my @drop_hwp_columns = qw(id hardware_product_id created updated deactivated);

    my $line = 0;

    my @headers = grep {
        my $col = $_;
        !any { $col eq $_ } @drop_hw_columns;
    } $self->app->db_hardware_products->result_source->columns;

    my @profile_headers = grep {
        my $col = $_;
        !any { $col eq $_ } @drop_hwp_columns;
    } $self->app->db_hardware_product_profiles->result_source->columns;

    my @specification_headers = qw(/chassis/memory/dimms /disk_size);

    while (my $hw = $rs->next) {
        if (not $line) {
            $csv->column_names(@headers, @profile_headers, @specification_headers);
            $csv->print($fh, [ @headers, @profile_headers, @specification_headers ]);
        }

        my $specification = Mojo::JSON::Pointer->new(from_json(delete $hw->{specification} // '{}'));
        $hw->{'/disk_size'} = $specification->get('/disk_size');
        if (my $dimms = $specification->get('/chassis/memory/dimms')) {
            my @dimmslots = map $_->{slot}, @$dimms;
            $hw->{'/chassis/memory/dimms'} = to_json(\@dimmslots);
        }

        @{$hw}{keys %{$hw->{hardware_product_profile}}} = values %{$hw->{hardware_product_profile}};
        delete @{$hw}{@drop_hw_columns};
        delete @{$hw->{hardware_product_profile}}{@drop_hwp_columns};
        delete $hw->{hardware_product_profile};

        $csv->print_hr($fh, $hw);
    }
    continue { ++$line }
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
