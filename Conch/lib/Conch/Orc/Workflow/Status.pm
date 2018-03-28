=head1 NAME

Conch::Orc::Workflow::Status

=head1 DESCRIPTION

Represents the overall status of a particular Workflow

=cut

package Conch::Orc::Workflow::Status;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Num ArrayRef Bool Str Enum InstanceOf);
use Types::UUID qw(Uuid);

use Conch::Pg;
use Conch::Orc;

=head1 CONSTANTS

	$status->status( Conch::Orc::Workflow::Status->ONGOING );

The following constants are available and link directly to values in the
C<e_workflow_status> enum in the database.


=over 4

=item ABORT

=item COMPLETED

=item ONGOING

=item RESUME

=item STOPPED

=back

=cut

use constant {
	ABORT     => 'abort',
	COMPLETED => 'completed',
	ONGOING   => 'ongoing',
	RESTART   => 'restart',
	RESUME    => 'resume',
	STOPPED   => 'stopped',
};


=head1 ACCESSORS

=over 4

=item id

UUID. Cannot be written by user.

=cut

has 'id' => (
	is  => 'rwp',
	isa => Uuid,
);


=item workflow_id

UUID. Required. FK'd into C<workflow(id)>

=cut

has 'workflow_id' => (
	is       => 'rw',
	required => 1,
	isa      => Uuid,
);


=item device_id

UUID. Required. FK'd into C<device(id)>

=cut

has 'device_id' => (
	is       => 'rw',
	required => 1,
	isa      => Str,
);


=item created

Conch::Time. Defaults to C<<< Conch::Time->now >>>. Represents the time this
status update occurred

=cut

has 'created' => (
	is      => 'rw',
	isa     => InstanceOf["Conch::Time"],
	default => sub { Conch::Time->now() },
);


=item status

One of the constants listed above. Defaults to ONGOING

=cut

has 'status' => (
	is      => 'rw',
	isa     => Enum[ ABORT, COMPLETED, ONGOING, RESUME, STOPPED, RESTART ],
	default => ONGOING,
);

=back

=head1 METHODS

=head2 workflow

A C<Conch::Orc::Workflow> object, loaded using C<workflow_id>

=cut

sub workflow ($self) { 
	return Conch::Orc::Workflow->from_id($self->workflow_id);
};


=head2 device

A C<Conch::Model::Device> object, loaded using C<device_id>

=cut

sub device ($self) {
	return Conch::Model::Device->lookup($self->device_id);
}



=head2 from_id

Load a Status from its UUID

=cut

sub from_id ($class, $uuid) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select('workflow_status', undef, { 
			id => $uuid
		})->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_id: $_");
		return undef;
	};

	return $class->new(
		device_id   => $ret->{device_id},
		id          => $ret->{id},
		status      => $ret->{status},
		created     => Conch::Time->new($ret->{created}),
		workflow_id => $ret->{workflow_id},
	);
}


=head2 many_from_device

	my $device = Conch::Model::Device->from_id('wat');
	my $many = Conch::Orc::Workflow::Status->many_from_device($device);

Returns an arrayref containing all the Status objects for a given Device,
sorted by created.

=cut

sub many_from_device($class, $d) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select('workflow_status', undef, { 
			device_id => $d->id
		}, { -asc => 'created' })->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->many_from_device: $_");
		return undef;
	};

	unless (scalar $ret->@*) {
		return [];
	}

	my @many = map {
		my $s = $_;
		$s->{created} = Conch::Time->new($s->{created});
		$class->new($s);
	} $ret->@*;

	return \@many;
}



=head2 latest_from_device

	my $device = Conch::Model::Device->from_id('wat');
	my $many = Conch::Orc::Workflow::Status->latest_from_device($device);

Returns a single Status object, representing the most recent Status for a given
device.

=cut

sub latest_from_device($class, $d) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->query(qq|
			select * from workflow_status where device_id = ?
				order by created asc
				limit 1
		|, $d->id)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->latest_from_device: $_");
		return undef;
	};

	return undef unless $ret;

	$ret->{created} = Conch::Time->new($ret->{created});
	return $class->new($ret->%*);
}



=head2 save

Saves or updates the Status

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my $tx = $db->begin;
	my $ret;
	my %fields = (
		device_id   => $self->device_id,
		status      => $self->status,
		created     => $self->created->timestamptz,
		workflow_id => $self->workflow_id,
	);
	try {
		if($self->id) {
			$ret = $db->update(
				'workflow_status',
				\%fields,
				{ id => $self->id }, 
				{ returning => [qw(id created)]}
			)->hash;
		} else {
			$ret = $db->insert(
				'workflow_status',
				\%fields,
				{ returning => [qw(id created)] }
			)->hash;
		}
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->save: $_");
		return undef;
	};
	$tx->commit;

	$self->_set_id($ret->{id});
	$self->created(Conch::Time->new($ret->{created}));

	return $self;
}


=head2 serialize

Returns a hashref, representing the Status in a serialized format

=cut

sub serialize ($self) {
	{
		device_id   => $self->device_id,
		id          => $self->id,
		status      => $self->status,
		created     => $self->created->rfc3339,
		workflow_id => $self->workflow_id,
	}
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

