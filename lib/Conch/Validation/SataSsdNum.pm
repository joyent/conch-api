package Conch::Validation::SataSsdNum;

use Mojo::Base 'Conch::Validation';
use v5.20;

use constant name        => 'sata_ssd_num';
use constant version     => 1;
use constant category    => 'DISK';
use constant description => 'Validate expected number of SATA SSDs';

sub validate {
    my ($self, $data) = @_;

    $self->die("Input data must include 'disks' hash")
        unless $data->{disks} && ref($data->{disks}) eq 'HASH';

    my $hw_profile = $self->hardware_product_profile;

    my $sata_ssd_count =
        grep { $_->{drive_type} && fc($_->{drive_type}) eq fc('SATA_SSD') }
        (values $data->{disks}->%*);

    my $sata_ssd_want = $hw_profile->sata_ssd_num || 0;

    # Joyent-Compute-Platform-3302 special case. HCs can have 8 or 16
    # Intel SATA SSDs and there's no other identifier. Here, we want
    # to avoid missing failed/missing disks, so we jump through a couple
    # extra hoops.
    if ($self->hardware_legacy_product_name // '' eq "Joyent-Compute-Platform-3302") {
        if ($sata_ssd_count <= 8) { $sata_ssd_want = 8; }
        if ($sata_ssd_count > 8)  { $sata_ssd_want = 16; }
    }

    $self->register_result(
        expected => $sata_ssd_want,
        got      => $sata_ssd_count,
    );
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
