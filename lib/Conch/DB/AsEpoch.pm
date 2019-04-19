package Conch::DB::AsEpoch;
use v5.26;
use warnings;
use experimental 'signatures';

=head1 NAME

Conch::DB::AsEpoch

=head1 DESCRIPTION

A component for Conch::DB::ResultSet classes that provides the 'as_epoch' method.

This code is postgres-specific.

=head1 USAGE

    __PACKAGE__->load_components('+Conch::DB::AsEpoch');

=head1 METHODS

=head2 as_epoch

Adds to a resultset a selection list for a timestamp column as a unix epoch time.
If the column already existed in the selection list (presumably using the default time format),
it is replaced.

In this example, a 'created' column will be included in the result, containing a value in unix
epoch time format (number of seconds since 1970-01-01 00:00:00 UTC).

    $rs = $rs->as_epoch('created');

=cut

sub as_epoch ($self, $column_name) {
    Carp::croak('missing column_name') if not $column_name;

    my $me = $self->current_source_alias;
    $self->search(
        undef,
        {
            # avoid "inflate_result() alias 'COL' specified twice with different SQL-side {select}-ors"
            # if this stops working, some other component has messed up our isa heirarchy and
            # stopped the ::RemoveColumns::_resolved_attrs method modifier from running
            remove_columns => [ $column_name ],
            '+columns' => {
                $column_name => {
                    '' => \('extract(epoch from '.$me.'.'.$column_name.')'),
                    -as => $column_name,
                },
            },
        },
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
# vim: set ts=4 sts=4 sw=4 et :
