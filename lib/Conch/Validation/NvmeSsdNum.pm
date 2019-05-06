package Conch::Validation::NvmeSsdNum;

use Mojo::Base 'Conch::Validation';
use v5.20;

use constant name        => 'nvme_ssd_num';
use constant version     => 1;
use constant category    => 'DISK';
use constant description => 'Validate expected number of NVMe SSDs';

sub validate {
    my ($self, $data) = @_;

    $self->die("Input data must include 'disks' hash")
        unless $data->{disks} && ref($data->{disks}) eq 'HASH';

    my $hw_profile = $self->hardware_product_profile;

    my $nvme_ssd_count =
        grep { $_->{drive_type} && fc($_->{drive_type}) eq fc('NVME_SSD') }
        (values $data->{disks}->%*);

    $self->register_result(
        expected => $hw_profile->nvme_ssd_num || 0,
        got      => $nvme_ssd_count,
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
