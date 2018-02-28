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
use DateTime::Format::Strptime;
use Carp 'croak';

use overload
	'""' => 'to_string',
	eq   => 'compare',
	ne   => sub { !compare(@_) };

=head2 timestamp

Underlying RFC 3339 formatted timestamp

=cut

has 'timestamp';

=head2 new
=cut

my $pg_timestamp_format =
qr/^(\d{4,})-(\d{2,})-(\d{2,}) (\d{2,}):(\d{2,}):(\d{2,})(\.\d+)?([-\+][\d:]+)$/;

sub new ( $class, $timestamptz ) {
	croak 'Invalid Postgres timestamp'
		unless $timestamptz && ( $timestamptz =~ m/$pg_timestamp_format/ );
	my $dt = "$1-$2-$3T$4:$5:$6." . _normalize_millisec($7) . _normalize_tz($8);
	$class->SUPER::new( timestamp => $dt );
}

# Given a float, return the number of integer milliseconds it represents
sub _normalize_millisec {
	substr( sprintf( '%.3f', shift || 0 ), 2 );
}

sub _normalize_tz {
	my $tz = shift;
	# return 'Z' if the timezone is 00 or 00:00
	return 'Z' if $tz =~ /^[-\+]00(?!:[1-9]\d)/;
	# Append :00 if the timezone doesn't specify minutes
	return $tz . ':00' if $tz =~ /^[-\+]\d\d$/;
	return $tz;
}

my $_parser = DateTime::Format::Strptime->new(
	pattern  => '%Y-%m-%dT%H:%M:%S.%3N%z',
	on_error => 'croak'
);

=head2 to_datetime

Return a C<DateTime> object representing the timestamp.

B<NOTE:> This method will negatively impact performance if called frequently.

=cut

sub to_datetime {
	return $_parser->parse_datetime( shift->timestamp );
}

=head2 compare

Compare two Conch::Time objects. Used to overload C<eq> and C<ne>.

=cut

sub compare {
	my ( $self, $other ) = @_;
	$self->timestamp eq $other->timestamp;
}

=head2 to_string

Render the timestamp as a RFC 3337 timestamp string. Used to
overload string coercion.

=cut

sub to_string {
	shift->timestamp;
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
