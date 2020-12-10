package Conch::DB::Helper::ResultSet::ResultsExist;
use v5.26;
use warnings;
use experimental 'signatures';

=head1 NAME

Conch::DB::Helper::ResultSet::ResultsExist

=head1 DESCRIPTION

A component for L<Conch::DB::ResultSet> classes that provides the C<exists> method.

See also L<DBIx::Class::Helper::ResultSet::Shortcut::ResultsExist>.

This code is postgres-specific but may work on other databases as well.

=head1 USAGE

    __PACKAGE__->load_components('+Conch::DB::Helper::ResultSet::ResultsExist');

=head1 METHODS

=head2 exists

Efficiently determines if a result exists, without needing to do a C<< ->count >>.
Essentially does:

    select * from ( select exists (select 1 from ... your query ... ) ) as _existence_subq;

Returns a value that you can treat as a boolean.

=cut

sub exists ($self) {
    my $inner_q = $self->_results_exist_as_query;
    my (undef, $sth) = $self->result_source
                        ->schema
                        ->storage
                        ->_select($inner_q, \'*', {}, {});

    my ($exists) = $sth->fetchrow_array;
    return $exists;
}

sub _results_exist_as_query ($self) {
    my $inner_q = $self->search(undef, { select => [ \1 ] })->as_query;
    $$inner_q->[0] = '( select exists '.$$inner_q->[0].' ) as _existence_subq';
    $inner_q;
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
