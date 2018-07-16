
=head1 NAME

Conch::Model::DatacenterRackLayout

=cut

package Conch::Model::DatacenterRackLayout;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use Moo::Role::ToJSON;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Str Int Undef);
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

=item rack_id

UUID. Required. FK into datacenter_rack(id)

=cut

has 'rack_id' => (
	is => 'rw',
	isa => Uuid,
	required => 1,
);


=item product_id

UUID. Required. FK into hardware_product(id)

=cut

has 'product_id' => (
	is => 'rw',
	isa => Uuid,
	required => 1,
);


=item ru_start

Int. Required.

=cut

has 'ru_start' => (
	is => 'rw',
	isa => Int,
	required => 1,
);

sub _build_serializable_attributes {[qw[
	id
	rack_id
	product_id
	ru_start
	created
	updated
]]}


=head1 METHODS

=head2 from_id

	my $o = Conch::Model::DatacenterRackLayout->from_id($uuid);

Retrieve a datacenter rack layout, given its UUID.

=cut

sub from_id ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter_rack_layout',
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

=head2 from_rack_id

	my $o = Conch::Model::DatacenterRackLayout->from_rack_id($uuid);

Retrieve a datacenter rack layout, given a rack UUID

=cut

sub from_rack_id ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter_rack_layout',
			undef,
			{
				rack_id => $id,
			}
		)->hashes->map(sub {
			$class->new(_fixup_timestamptzs($_)->%*);
		})->to_array;

	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_rack_id: $_");
		return undef;
	};

	return $ret;
}

=head2 all

	my @o = Conch::Model::DatacenterRackLayout->all()->@*;

Retrieve all datacenter rack layouts

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select(
			'datacenter_rack_layout',
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

	$o->save();

Insert or update the datacenter rack layout in the database.

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my %fields = $self->%*;
	delete $fields{id};
	delete $fields{serializable_attributes};

	if ($fields{created}) {
		$fields{created} = $fields{created}->timestamptz;
	}

	$fields{updated} = 'NOW()';

	my $ret;
	try {
		if($self->id) {
			$ret = $db->update(
				'datacenter_rack_layout',
				\%fields,
				{ id => $self->id },
				{ returning => [qw(id created updated)] }
			)->hash;
		} else {
			$ret = $db->insert(
				'datacenter_rack_layout',
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

	$o->burn;

Delete the object in the database. This is a destructive action.

=cut

sub burn ($self) {
	return $self unless $self->id;
	try {
		Conch::Pg->new->db->delete('datacenter_rack_layout', { id => $self->id });
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

