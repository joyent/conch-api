package Conch::Validation::LinksUp;

use Mojo::Base 'Conch::Validation';

use constant name        => 'links_up';
use constant version     => 2;
use constant category    => 'NET';
use constant description => 'Validate that there are at least 4 NICs in the \'up\' state, not counting ipmi1';

sub validate {
    my ($self, $data) = @_;

    $self->die("Input data must include 'interfaces' hash")
        unless $data->{interfaces} && ref($data->{interfaces}) eq 'HASH';

    my $links_up = 0;
    while (my ($name, $nic) = each $data->{interfaces}->%*) {
        next if $name eq 'ipmi1';
        $links_up++ if ($nic->{state} && $nic->{state} eq 'up');
    }

    $self->register_result(
        expected => 4,
        cmp      => '>=',
        got      => $links_up
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
