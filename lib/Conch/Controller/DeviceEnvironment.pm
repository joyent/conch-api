package Conch::Controller::DeviceEnvironment;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

=pod

=head1 NAME

Conch::Controller::DeviceEnvironment

=head1 METHODS

=head2 process

Receives environment data for a particular device:

- records to the database
- dispatches to Circonus/Prometheus (TODO)
- sends to a validation (TODO) (what to do when validation fails?)

=cut

sub process ($c) {
    my $data = $c->validate_input('EnvironmentData');
    return if not $data;

    my $device_rs = $c->stash('device_rs');

    my %environment = (
        $data->{temp} ? (
            cpu0_temp    => $data->{temp}{cpu0},
            cpu1_temp    => $data->{temp}{cpu1},
            inlet_temp   => $data->{temp}{inlet},
            exhaust_temp => $data->{temp}{exhaust},
        ) : (),
        $data->{voltage} ? (
            psu0_voltage => $data->{voltage}{psu0},
            psu1_voltage => $data->{voltage}{psu1},
        ) : (),
    );

    $device_rs->related_resultset('device_environment')->update_or_create({
        %environment,
        updated => \'now()',
    }) if keys %environment;

    if ($data->{disks} and keys $data->{disks}->%*) {
        foreach my $disk_serial (keys $data->{disks}->%*) {
            my $disk = $device_rs->related_resultset('device_disks')->find(
                { serial_number => $disk_serial },
                { key => 'device_disk_serial_number_key' },
            );
            if (not $disk) {
                $c->log->debug('received environment data for non-existent disk: device id '
                    .$c->stash('device_id').", serial number $disk_serial");
                next;
            }

            $disk->update({
                temp => $data->{disks}{$disk_serial}{temp},
                updated => \'now()',
            });
        }
    }

    $c->log->info('recorded environment data for device '.$c->stash('device_id'));

    # TODO: send to Circonus/Prometheus.

    # TODO: run validations?
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
