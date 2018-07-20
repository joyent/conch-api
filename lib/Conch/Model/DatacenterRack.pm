=head1 NAME

Conch::Model::DatacenterRack

=cut

package Conch::Model::DatacenterRack;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use Moo::Role::ToJSON;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Str);
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


=item name

String. Required.

=cut

has 'name' => (
	is       => 'rw',
	isa      => Str,
	required => 1,
);

=item datacenter_room_id

UUID. Required. FK to datacenter_room(id)

=cut

has 'datacenter_room_id' => (
	is => 'rw',
	isa => Uuid,
	required => 1,
);

=item role

UUID. Required. FK to datacenter_rack_role(id)

=cut

has 'role' => (
	is => 'rw',
	isa => Uuid,
	required => 1,
);


sub _build_serializable_attributes {[qw[
	id
	name
	datacenter_room_id
	role
	created
	updated
]]}



=back

=head1 METHODS

=head2 from_id

	my $rack = Conch::Model::DatacenterRack->from_id($uuid);

Returns a Rack given an existing UUID.

=cut

sub from_id ($class, $uuid) {
	$class->_from(id => $uuid);
}

=head2 from_name

	my $rack = Conch::Model::DatacenterRack->from_name($name);

Returns a Rack given an existing name

=cut

sub from_name ($class, $name) {
	$class->_from(name => $name);
}


sub _from ($class, $key, $value) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select(
			'datacenter_rack', 
			undef,
			{ $key => $value }
		)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->_from: $_");
		return undef;
	};

	return undef unless $ret;
	return $class->new(_fixup_timestamptzs($ret));
}


=head2 all

	my @racks = Conch::Model::DatacenterRack->all()->@*;

Returns an arrayref of all rack

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select(
			'datacenter_rack',
		)->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->all: $_");
		return undef;
	};

	return [] unless $ret and $ret->@*;

	my @many = map {
		$class->new(_fixup_timestamptzs($_)->%*);
	} $ret->@*;

	return \@many;
}


=head2 from_datacenter_room

	my @racks = Conch::Model::DatacenterRack->from_datacenter_room($uuid)->@*;

Returns all racks in a given datacenter room

=cut

sub from_datacenter_room ($class, $uuid) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter_rack',
			undef,
			{
				datacenter_room_id => $uuid,
			}
		)->hashes->map(sub {
			$class->new(_fixup_timestamptzs($_)->%*);
		})->to_array;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_datacenter_room: $_");
		return undef;
	};

	return $ret;
}


=head2 save

	$rack->save();

Create or update the rack in the database.

Returns C<$self>

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my %fields = $self->%*;
	delete $fields{id};
	delete $fields{serializable_attributes};

	if($fields{created}) {
		$fields{created} = $fields{created}->timestamptz;
	}
	$fields{'updated'} = 'NOW()';

	my $ret;
	try {
		if($self->id) {
			$ret = $db->update(
				'datacenter_rack',
				\%fields,
				{ id => $self->id },
				{ returning => [qw|id created updated|] }
			)->hash;
		} else {
			$ret = $db->insert(
				'datacenter_rack',
				\%fields,
				{ returning => [qw|id created updated|] }
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

	$rack->burn();

Delete the rack from the database. This is a destructive operation.

Returns C<$self>

=cut

sub burn ($self) {
	return $self unless $self->id;
	try {
		Conch::Pg->new->db->delete('datacenter_rack', { id => $self->id });
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

