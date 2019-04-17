package Conch::Validation::RamTotal;

use Mojo::Base 'Conch::Validation';
use List::Util 'sum';

use constant name        => 'ram_total';
use constant version     => 2;
use constant category    => 'RAM';
use constant description => q(
Validate the reported RAM match the hardware product profile
);

sub validate {
    my ($self, $data) = @_;

    unless(exists $data->{dimms} && $data->{dimms}->@*) {
        $self->die("Missing 'dimms' property");
    }


    my $hw_profile = $self->hardware_product_profile;

    my $ram_total = sum map { $_->{'memory-size'} // 0 } $data->{dimms}->@*;
    my $ram_want  = $hw_profile->ram_total;

    $self->register_result(
        expected => $ram_want,
        got      => $ram_total,
    );
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
