=pod

=head1 NAME

Conch::Time - format timestamps as RFC 3337 UTC timestamps

=head1 SYNOPSIS

    use Conch::Time;

    my $postgres_timestamp = '2018-01-26 12:24:18.893874-07';
    my $time = Conch::Time->new($postgres_timestamp);

    $time eq $time; # 1

=head1 METHODS

=cut

package Conch::Time;

use v5.26;
use strict;
use warnings;

use parent 'Time::Moment';

=head2 new

Overloads the constructor to use C<< ->from_string >> when a single argument is passed.

    Conch::Time->new($pg_timestamptz);

    ... and any other constructor modes supported by Time::Moment

=cut

sub new {
    my $class = shift;

    if (@_ == 1) {
        return bless(Time::Moment->from_string($_[0], lenient => 1), $class);
    }

    return $class->SUPER::new(@_);
}

=head2 now

    my $t = Conch::Time->now;

Return an object based on the current time, using the UTC timezone.

Time are high resolution and will generate unique timestamps to the
nanosecond.

=cut

sub now { return shift->now_utc }

=head2 from_epoch

    Conch::Time->from_epoch(time);

    Conch::Time->from_epoch(Time::HiRes::gettimeofday);

    Conch::Time->from_epoch(1234567890, 123);

See also L<Time::Moment/from_epoch>.

=head2 CONVERSIONS

=head3 rfc3339

Return an RFC3339 compatible string as UTC.
Sub-second precision will use 3, 6 or 9 digits as necessary.

=cut

sub rfc3339 {
    return shift->at_utc->strftime('%Y-%m-%dT%H:%M:%S.%N%Z');
}

=head3 timestamp

Return an RFC3339 compatible string.

=cut

sub timestamp { goto &rfc3339 }

=head3 to_string

Render the timestamp as a RFC 3339 timestamp string. Used to
overload string coercion.

=cut

sub to_string { goto &rfc3339 }

=head3 TO_JSON

Renderer for Mojo, as a RFC 3339 timestamp string

=cut

sub TO_JSON { goto &rfc3339 }

=head3 timestamptz

Render a string in PostgreSQL's timestamptz style

=cut

sub timestamptz {
    return shift->strftime('%Y-%m-%d %H:%M:%S%f%z');
}

=head3 iso8601

Render the timestamp as an ISO8601 extended format, in UTC

=cut

sub iso8601 {
    return shift->at_utc->strftime('%Y-%m-%dT%H:%M:%S%f%Z');
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
