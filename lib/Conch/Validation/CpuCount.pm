package Conch::Validation::CpuCount;

use Mojo::Base 'Conch::Validation';

use constant name        => 'cpu_count';
use constant version     => 2;
use constant category    => 'CPU';
use constant description => 'Validate the reported number of CPUs match the hardware product profile';

sub validate {
    my ($self, $data) = @_;

    unless ($data->{cpus}) {
        $self->die("Missing cpus property")
    }

    my $hw_profile = $self->hardware_product_profile;

    $self->register_result(
        expected => $hw_profile->cpu_num,
        got      => scalar $data->{cpus}->@*,
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
