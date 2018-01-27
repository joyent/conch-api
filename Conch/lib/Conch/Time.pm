=pod

=head1 NAME

Conch::Time - format Postgres Timestamps as RFC 3337 UTC timestamps

=head1 SYNOPSIS

	use Conch::Time;

	my $postgres_timestamp = '2018-01-26 12:24:18.893874-07';
	my $time = Conch::Time->new($postgres_timestamp);

	say $time; # '2018-01-26T12:24:18.893Z'
	$time eq $time; # 1


=head1 METHODS

=cut
package Conch::Time;
use Mojo::Base -base, -signatures;
use overload
	'""' => 'to_string',
	eq => 'compare',
	ne => sub { !compare(@_) };

use DateTime::Format::Pg;

=head2 datetime

Underlying L<DateTime> object.

=cut

has 'datetime';

=head2 new
=cut
sub new ( $class, $timestamptz ) {
	my $dt = DateTime::Format::Pg->parse_timestamptz($timestamptz);
	$class->SUPER::new( datetime => $dt );
}

=head2 compare

Compare two Conch::Time objects. Used to overload C<eq> and C<ne>.

=cut
sub compare {
	my ( $self, $other ) = @_;
	$self->datetime eq $other->datetime;
}

=head2 to_string

Render the timestamp as a RFC 3337 string with the UTC suffix C<Z>. Used to
overload string coercion.

=cut
sub to_string {
	my $self = shift;
	$self->datetime->strftime('%Y-%m-%dT%H:%M:%S.%3NZ');
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
