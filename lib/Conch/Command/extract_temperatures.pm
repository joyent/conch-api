package Conch::Command::extract_temperatures;

=pod

=head1 NAME

extract_temperatures - extract temperatures from historical device reports

=head1 SYNOPSIS

    extract_temperatures [long options...]

        --dir   directory to create data files in
        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Mojo::JSON 'from_json', 'encode_json';

has description => 'extract temperatures from historical device reports';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run {
    my $self = shift;

    local @ARGV = @_;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'extract_temperatures %o',
        [ 'dir|d=s',        'directory to create data files in' ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    if ($opt->dir) {
        say 'creating files in ', $opt->dir, '...';
        mkdir $opt->dir if not -d $opt->dir;
        chdir $opt->dir;
    }

    # process reports in pages of 100 rows each
    my $device_report_rs = $self->app->db_ro_device_reports
        ->rows(100)
        ->page(1)
        ->hri;  # raw hashref data; do not inflate to objects or alter timestamps

    my $num_pages = $device_report_rs->pager->last_page;
    foreach my $page (1 .. $num_pages) {
        print "\n" if $page % 100 == 0;
        print '.';

        $device_report_rs = $device_report_rs->page($page);
        while (my $device_report = $device_report_rs->next) {

            my $data = from_json($device_report->{report});

            # TODO: I have no idea if this is the desired format! adjust as needed.

            my $temp = +{
                $data->{temp}->%*,

                (map {; "disk_$_" => $data->{disks}{$_}{temp} }
                    grep { exists $data->{disks}{$_}{temp} }
                    keys $data->{disks}->%*),
            };

            my $fan_speeds = +{
                (map {; "fan_$_" => $data->{fans}{units}[$_]{speed_pct} }
                    grep { exists $data->{fans}{units}[$_]{speed_pct} }
                    0 .. $data->{fans}{count} - 1),
            };

            my $psus = +{
                (map {;
                    my $num = $_;
                    "psu_$num" => +{
                        map { $_ => $data->{psus}{units}[$num]{$_} }
                            grep { /^(amps|volts|watts)/ }
                            keys $data->{psus}{units}[$num]->%*
                    }
                }
                0 .. $data->{psus}{count} - 1),
            };

            my $output_data = {
                date => $device_report->{created},
                device_id => $device_report->{device_id},
                ( keys %$temp ? ( temp => $temp ) : () ),
                ( keys %$fan_speeds ? ( fan_speeds => $fan_speeds ) : () ),
                ( keys %$psus ? ( psus => $psus ) : () ),
            };

            next if keys %$output_data == 2;

            my $fh = $self->_fh_for_date($device_report->{created});
            print $fh encode_json($output_data), "\n";
        }
    }

    print "\n\ndone.\n";
}

my %fh_cache;

sub _fh_for_date ($self, $timestamp) {

    my $date = Conch::Time->new($timestamp)->strftime('%Y-%m-%d');

    return $fh_cache{$date} if exists $fh_cache{$date};

    # we're on a new date; close the old file and open a new one
    close $_ foreach values %fh_cache;

    # use raw binmode, as json data will be utf8-encoded if needed.
    open $fh_cache{$date}, '>', "temperatures-$date.json"
        or die "could not open temperatures-$date.json for writing: $!";
    return $fh_cache{$date};
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
