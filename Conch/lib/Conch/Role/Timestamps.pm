=head1 NAME

Conch::Role::Timestamps

=head1 SYNOPSIS

	package MyMooThing;
	use Moo;
	use Conch::Time;
	with("Conch::Role::Timestamps");

	sub deactivate {
		my $self = shift;
		$self->deactivated(Conch::Time->now);
	}

=head1 DESCRIPTION

Most of our database tables have three timestamps on them: created, updated,
and deactivated. This role adds Moo attributes for those so we can avoid
copy-paste.


=head1 ACCESSORS

=over 4

=cut

package Conch::Role::Timestamps;

use strict;
use warnings;
use utf8;
use v5.20;

use Type::Tiny;
use Types::Standard qw(InstanceOf Undef);

use Moo::Role;

use experimental qw(signatures);

use Conch::Time;


=item created

Conch::Time. Cannot be written by user.

=cut

has 'created' => (
	is => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item updated

Conch::Time. Cannot be written by user.

=cut

has 'updated' => (
	is  => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item deactivated

Conch::Time. May be undef

=cut

has 'deactivated' => (
	is  => 'rw',
	isa => InstanceOf["Conch::Time"] | Undef
);


=back

=head1 FUNCTIONS

=head2 _fixup_timestamptzs

	my $data = _fixup_timestamptzs({ created => $timestamptz});

Takes a hash ref that probably contains timestamptz versions of C<created>,
C<updated>, and/or C<deactivated>. Converts those values B<in place> to
C<Conch::Time> objects.

B<Again: This modifies the provided hashref and overwrites the original
timetamp fields.>

=cut


sub _fixup_timestamptzs ($data) {
	for my $k (qw(created updated deactivated)) {
		if($data->{$k}) {
			$data->{$k} = Conch::Time->new($data->{$k});
		}
	}
	return $data;
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

