package Conch::DB::InflateColumn::Time;

use v5.26;
use warnings;
use experimental 'signatures';
use parent 'DBIx::Class::InflateColumn::TimeMoment';

use Conch::Time;

=pod

=head1 DESCRIPTION

Automatically inflates/deflates timestamps in the database to Conch::Time objects (which
is a subclass of L<Time::Moment>).

No extra work needs to be done for deflation, because postgres is happy to accept our slight
modifications to the format used in C<to_string>.  All we need to do is rebless the
L<Time::Moment> object into Conch::Time, and work around the bug in
L<RT#125975|https://rt.cpan.org/Ticket/Display.html?id=125975>.

=cut

sub _post_inflate_timemoment ($self, $dt, $info) {
    # _inflate_to_timemoment gave us a Time::Moment.
    # now we turn that into a Conch::Time.
    return bless($dt, 'Conch::Time');
}

sub register_column ($self, $column, $info, @rest) {
    return $self->next::method($column, $info, @rest)
        if $info->{data_type} ne 'timestamp with time zone';

    # fool ::TimeMoment into thinking we can serialize this.
    # see https://rt.cpan.org/Ticket/Display.html?id=125975
    my %patched_info = (
        $info->%*,
        data_type => 'datetime',
    );

    return $self->next::method($column, \%patched_info, @rest)
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
