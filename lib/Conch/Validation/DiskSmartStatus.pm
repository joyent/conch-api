package Conch::Validation::DiskSmartStatus;

use Mojo::Base 'Conch::Validation';
use v5.20;

use constant name     => 'disk_smart_status';
use constant version  => 2;
use constant category => 'DISK';
use constant description => 'Validate that all real disks report \'OK\' SMART status';

sub validate {
    my ($self, $data) = @_;

    $self->die("Input data must include 'disks' hash")
        unless $data->{disks} && ref($data->{disks}) eq 'HASH';

    $self->die("'disks' hash is empty")
        unless $data->{disks}->%*;

    # Check for a not-OK, non-USB/RAID drive using its SMART data.
    # This is provided on the host by smartctl -a <dev>
    while (my ($disk_sn, $disk) = each $data->{disks}->%*) {
        next if !$disk->{transport} ||
            fc($disk->{transport}) eq fc('usb') ||
            fc($disk->{drive_type}) eq fc('RAID_LUN');

        $self->fail("No health reported for disk $disk_sn") && next
            unless defined($disk->{health});

        $self->register_result(
            expected     => 'OK',
            got          => $disk->{health},
            component    => $disk_sn
        );
    }
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
