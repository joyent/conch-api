package Conch::DB::Helper::Row::WithPhase;
use v5.26;
use warnings;

use parent 'DBIx::Class::Core';

=head1 NAME

Conch::DB::Helper::Row::WithPhase

=head1 DESCRIPTION

A component for L<Conch::DB::Result> classes for database tables with a C<phase> column, to
provide common functionality.

=head1 USAGE

    __PACKAGE__->load_components('+Conch::DB::Helper::Row::WithPhase');

=head1 METHODS

=head2 phase_cmp

Acts like the C<cmp> operator, returning -1, 0 or 1 depending on whether the first phase is
less than, the same as, or greater than the second phase.

If only one phase argument is passed, the phase in the current row is compared to the passed-in
phase.

Accepts undef for one or both phases, which always compare as less than a defined phase.

=cut

sub phase_cmp {
    my $self = shift;

    state $phase_to_int = do {
        my $i = 0;
        +{ map +($_ => ++$i), $self->column_info('phase')->{extra}{list}->@* };
    };

    my ($phase1, $phase2) =
        @_ == 2 ? (shift, shift)
      : @_ == 1 ? ($self->phase, shift)
      : die 'insufficient arguments';

    (defined $phase1 ? $phase_to_int->{$phase1} : 0) <=> (defined $phase2 ? $phase_to_int->{$phase2} : 0);
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
# vim: set sts=2 sw=2 et :
