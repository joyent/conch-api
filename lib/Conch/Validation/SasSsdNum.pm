package Conch::Validation::SasSsdNum;

use Mojo::Base 'Conch::Validation';
use v5.20;

use constant name        => 'sas_ssd_num';
use constant version     => 2;
use constant category    => 'DISK';
use constant description => 'Validate expected number of SAS SSDs';

sub validate {
    my ($self, $data) = @_;

    $self->die("Input data must include 'disks' hash")
        unless $data->{disks} && ref($data->{disks}) eq 'HASH';

    my @disks_with_drive_type =
        grep { $_->{drive_type} } (values $data->{disks}->%*);

    my $sas_ssd_count = grep {
        fc($_->{drive_type}) eq fc('SAS_SSD')
    } @disks_with_drive_type;

    my $sas_ssd_want = $self->hardware_product->sas_ssd_num;

    $self->register_result(
        expected => $sas_ssd_want,
        got      => $sas_ssd_count,
    );
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
