package Conch::Validation::DimmCount;

use Mojo::Base 'Conch::Validation';

use constant name        => 'dimm_count';
use constant version     => 3;
use constant category    => 'RAM';
use constant description => 'Verify the number of DIMMs reported';

sub validate {
    my ($self, $data) = @_;

    unless($data->{dimms}) {
        $self->die("Missing 'dimms' property");
    }

    my $dimms_num  = scalar grep $_->{'memory-size'} || $_->{'memory-type'},
        $data->{dimms}->@*;
    my $dimms_want = $self->hardware_product->dimms_num;

    $self->register_result(
        expected => $dimms_want,
        got      => $dimms_num,
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
