package Conch::DB::ResultSet::RackLayout;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::RackLayout

=head1 DESCRIPTION

Interface to queries involving rack layouts.

=head1 METHODS

=head2 with_rack_unit_size

Chainable resultset that adds C<rack_unit_size> to the results.

=cut

sub with_rack_unit_size ($self) {
    $self->search(undef, {
        join => { hardware_product => 'hardware_product_profile' },
        '+columns' => { rack_unit_size => 'hardware_product_profile.rack_unit' },
        collapse => 1,
    });
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
# vim: set ts=4 sts=4 sw=4 et :
