=head1 NAME

Conch::Model::Datacenter

=cut

package Conch::Model::Datacenter;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use Moo::Role::ToJSON;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Str Undef);
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


=item vendor

String. Required

=cut

has 'vendor' => (
	is => 'rw',
	isa => Str,
	required => 1,
);


=item vendor_name

String. Required

=cut

has 'vendor_name' => (
	is => 'rw',
	isa => Str | Undef,
);


=item region

String. Required

=cut

has 'region' => (
	is => 'rw',
	isa => Str,
	required => 1,
);


=item location

String. Required.

=cut

has 'location' => (
	is => 'rw',
	isa => Str,
	required => 1,
);

sub _build_serializable_attributes {[qw[
	id
	vendor
	vendor_name
	region
	location
	created
	updated
]]}


=head1 METHODS

=head2 from_id

	my $dc = Conch::Model::Datacenter->from_id($uuid);

Retrieve a datacenter, given its UUID.

=cut

sub from_id ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter',
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

	my @dc = Conch::Model::Datacenter->all()->@*;

Retrieve all datacenters.

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter',
			undef,
			undef,
		)->hashes->map(sub {
			$class->new(_fixup_timestamptzs($_)->%*);
		})->to_array;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->all: $_");
		return undef;
	};

	return $ret;
}

=head2 save

	$dc->save();

Insert or update the datacenter in the database.

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
				'datacenter',
				\%fields,
				{ id => $self->id },
				{ returning => [qw(id created updated)] }
			)->hash;
		} else {
			$ret = $db->insert(
				'datacenter',
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

	$d->burn;

Delete the object in the database. This is a destructive action.

=cut

sub burn ($self) {
	return $self unless $self->id;
	try {
		Conch::Pg->new->db->delete('datacenter', { id => $self->id });
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

