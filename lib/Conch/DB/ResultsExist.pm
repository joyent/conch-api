package Conch::DB::ResultsExist;
use v5.26;
use warnings;
use experimental 'signatures';

=head1 NAME

Conch::DB::ResultsExist

=head1 DESCRIPTION

A component for Conch::DB::ResultSet classes that provides the 'exists' method.

See also L<DBIx::Class::Helper::ResultSet::Shortcut::ResultsExist>, which is not usable in its
present form due to L<https://github.com/frioux/DBIx-Class-Helpers/issues/54>.

This code is postgres-specific.

=head1 USAGE

    __PACKAGE__->load_components('+Conch::DB::ResultsExist');

=head1 METHODS

=head2 exists

Efficiently efficiently determines if a result exists, without needing to do a C<< ->count >>.
Essentially does:

    select exists (select 1 from ... rest of your query ...);

Returns a value that you can treat as a boolean.

=cut

sub exists ($self) {
    my $inner = $self->search(undef, { select => [ \1 ] })->as_query;

    my $statement = 'select exists '.$inner->$*->[0];
    my @binds = map +($_->[1]), $inner->$*->@[1 .. $inner->$*->$#*];

    my ($exists) = $self->result_source->schema->storage->dbh_do(sub ($storage, $dbh) {
        # cribbed from DBIx::Class::Storage::DBI::_format_for_trace
        $storage->debugobj->query_start($statement, map +(defined($_) ? qq{'$_'} : q{NULL}), @binds)
            if $storage->debug;

        $dbh->selectrow_array($statement, undef, @binds);
    });

    return $exists;
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
