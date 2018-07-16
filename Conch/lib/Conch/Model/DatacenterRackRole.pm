=head1 NAME

Conch::Model::DatacenterRackRole

=cut

package Conch::Model::DatacenterRackRole;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use Moo::Role::ToJSON;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Str Int);
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

=item rack_size

Int. Required
 
=cut

has 'rack_size' => (
	is       => 'rw',
	isa      => Int,
	required => 1,
);


sub _build_serializable_attributes {[qw[
	id
	name
	rack_size
	created
	updated
]]}



=back 4

=head1 METHODS

=head2 from_id

	my $role = Conch::Model::DatacenterRackRole->from_id($uuid);

Returns a Rack Role given an existing UUID.

=cut

sub from_id ($class, $uuid) {
	$class->_from(id => $uuid);
}

=head2 from_name

	my $role = Conch::Model::DatacenterRackRole->from_name($name);

Returns a Rack Role given an existing name

=cut

sub from_name ($class, $name) {
	$class->_from(name => $name);
}


sub _from ($class, $key, $value) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select(
			'datacenter_rack_role', 
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

	my @roles = Conch::Model::DatacenterRackRole->all()->@*;

Returns an arrayref of all rack roles

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select(
			'datacenter_rack_role',
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



=head2 save

	$role->save();

Create or update the rolein the database.

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
				'datacenter_rack_role',
				\%fields,
				{ id => $self->id },
				{ returning => [qw|id created updated|] }
			)->hash;
		} else {
			$ret = $db->insert(
				'datacenter_rack_role',
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

	$role->burn();

Delete the role from the database. This is a destructive operation.

Returns C<$self>

=cut

sub burn ($self) {
	return $self unless $self->id;
	try {
		Conch::Pg->new->db->delete('datacenter_rack_role', { id => $self->id });
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

