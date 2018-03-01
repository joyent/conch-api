=pod

=head1 NAME

Conch::Time - format Postgres Timestamps as RFC 3337 UTC timestamps

=head1 SYNOPSIS

	use Conch::Time;

	my $postgres_timestamp = '2018-01-26 12:24:18.893874-07';
	my $time = Conch::Time->new($postgres_timestamp);

	$time eq $time; # 1


=head1 METHODS

=cut

package Conch::Time;
use Mojo::Base -base, -signatures;

use POSIX qw(strftime);
use Time::Moment;
use Time::HiRes;
use Mojo::Exception;

use overload
	'""' => 'rfc3339',
	eq   => 'compare',
	ne   => sub { !compare(@_) };

use constant PG_TIMESTAMP_FORMAT => qr/
	^(\d{4,})-(\d{2,})-(\d{2,})\s
	(\d{2,}):(\d{2,}):(\d{2,})\.?(\d+)
	?([-\+])([\d:]+)$
/x;



has 'moment';

=head2 new

	Conch::Time->new($pg_timestamptz);

=cut

sub new ( $class, $timestamptz ) {
	my @c = ( $timestamptz =~ PG_TIMESTAMP_FORMAT );
	Mojo::Exception->throw('Invalid Postgres timestamp')
		unless @c;

	$c[6] = 0 unless $c[6];

	my $off_minutes;
	if ($c[8] =~ /:/) {
		my ($hours, $minutes) = $c[8] =~ /^(\d\d)[:]?(\d\d)$/;

		$off_minutes = ($hours*60);
		$off_minutes = $off_minutes + $minutes if $minutes;
	} else {
		$off_minutes = $c[8] * 60;
	}

	my $m = Time::Moment->new(
		year       => $c[0],
		month      => $c[1],
		day        => $c[2],
		hour       => $c[3],
		minute     => $c[4],
		second     => $c[5],
		nanosecond => $c[6]*1000,
		offset     => "${c[7]}${off_minutes}",
	);
	return $class->SUPER::new(moment => $m);
}



=head2 now

	my $t = Conch::Time->now();

Return an object based on the current time.

Time are high resolution and will generate unique timestamps to the
nanosecond.

=cut

sub now ($class) {
	return $class->SUPER::new(moment => Time::Moment->now());
}

=head2 from_epoch

	Conch::Time->from_epoch(time());

	Conch::Time->from_epoch(Time::HiRes::gettimeofday);

=cut

sub from_epoch ($class, $epoch, $nano = 0) {
	return $class->SUPER::new(moment => Time::Moment->from_epoch(
		$epoch,
		$nano,
	));
}


=head2 compare

Compare two Conch::Time objects. Used to overload C<eq> and C<ne>.

=cut

sub compare {
	my ( $self, $other ) = @_;
	return $self->moment->is_equal($other->moment)
}


=head2 CONVERSIONS

=head3 rfc3339

Return an RFC3339 compatible string

=cut

sub rfc3339 {
	my $self = shift;
	return $self->moment->strftime("%Y-%m-%dT%H:%M:%S.%3N%Z");
}




=head3 timestamp

Return an RFC3339 compatible string

=cut

sub timestamp { shift->rfc3339() }



=head3 to_string

Render the timestamp as a RFC 3339 timestamp string. Used to
overload string coercion.

=cut

sub to_string { shift->rfc3339 }

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
