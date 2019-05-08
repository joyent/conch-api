package Conch::Validation::NicsNum;

use Mojo::Base 'Conch::Validation';

use constant name        => 'nics_num';
use constant version     => 1;
use constant category    => 'NET';
use constant description => 'Validate the reported number of NICs match the hardware product profile';

sub validate {
    my ($self, $data) = @_;

    $self->die("Input data must include 'interfaces' hash")
        unless $data->{interfaces} && ref($data->{interfaces}) eq 'HASH';
    my $hw_profile = $self->hardware_product_profile;

    my $nics_count = scalar(keys $data->{interfaces}->%*);

    $self->register_result(
        expected => $hw_profile->nics_num,
        got      => $nics_count,
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
