=head1 NAME

Conch::Model::DatacenterRoom

=cut

package Conch::Model::DatacenterRoom;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use Moo::Role::ToJSON;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Str ArrayRef Undef);
use Types::UUID qw(Uuid);

use Conch::Pg;

with("Moo::Role::ToJSON");
with("Conch::Role::But");
with("Conch::Role::Timestamps");


=head1 ACCESSORS

=over 4

=item id

UUID. Cannot be written by user.

=cut

has 'id' => (
	is  => 'rwp',
	isa => Uuid,
);


=item datacenter

UUID. FK into datacenter(id)

=cut

has 'datacenter' => (
	is       => 'rw',
	isa      => Uuid,
	required => 1,
);


=item az

String. Required.

=cut

has 'az' => (
	is       => 'rw',
	isa      => Str,
	required => 1,
);


=item alias

String. May be undef.

=cut

has 'alias' => (
	is  => 'rw',
	isa => Str | Undef,
);


=item vendor_name

String. May be undef

=cut

has 'vendor_name' => (
	is => 'rw',
	isa => Str | Undef,
);


sub _build_serializable_attributes {[qw[
	id
	datacenter
	az
	alias
	vendor_name
	created
	updated
]]}

=back

=head1 METHODS

=head2 from_id

	my $r = Conch::Model::DatacenterRoom->from_id($uuid);

Retrieve a datacenter room, given its UUID.

=cut

sub from_id ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter_room',
			undef,
			{
				id => $id,
			}
		)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_id: $_");
		return undef;
	};

	return undef unless $ret;
	return $class->new(_fixup_timestamptzs($ret)->%*);
}

=head2 all

	my @r = Conch::Model::DatacenterRoom->all()->@*;

Retrieve all datacenter rooms.

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter_room',
		)->hashes->map(sub {
			$class->new(_fixup_timestamptzs($_)->%*);
		})->to_array;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->all: $_");
		return undef;
	};

	return $ret;
}

=head2 from_datacenter

	my $r = Conch::Model::DatacenterRoom->from_datacenter($uuid);

Retrieve all rooms for a given datacenter UUID.

=cut

sub from_datacenter ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter_room',
			undef,
			{
				datacenter => $id,
			}
		)->hashes->map(sub {
			$class->new(_fixup_timestamptzs($_)->%*);
		})->to_array;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_datacenter: $_");
		return undef;
	};

	return $ret;
}


=head2 save

	$r->save();

Insert or update a room in the database.

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my %fields = $self->%*;
	delete $fields{id};
	delete $fields{serializable_attributes};

	for my $k (qw(created updated)) {
		if ($fields{$k}) {
			$fields{$k} = $fields{$k}->timestamptz;
		}
	}

	$fields{updated} = 'NOW()';

	my $ret;
	try {
		if($self->id) {
			$ret = $db->update(
				'datacenter_room',
				\%fields,
				{ id => $self->id },
				{ returning => [qw(id created updated)] }
			)->hash;
		} else {
			$ret = $db->insert(
				'datacenter_room',
				\%fields,
				{ returning => [qw(id created updated)] }
			)->hash;
		}
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->save: $_");
		return undef;
	};
	$ret = _fixup_timestamptzs($ret);

	$self->_set_id($ret->{id});
	$self->_set_created($ret->{created});
	$self->_set_updated($ret->{updated});
	return $self;
}

=head2 burn

	$dr->burn;

Delete the room from the database. This is a destructive action.

Also removes the room from all workspaces

=cut

sub burn ($self) {
	return $self unless $self->id;
	try {
		Conch::Pg->new->db->delete('workspace_datacenter_room', {
			datacenter_room_id => $self->id
		});
		Conch::Pg->new->db->delete('datacenter_room', { id => $self->id });
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->burn: $_");
		return undef;
	};

	return $self;
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
