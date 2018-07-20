=head1 NAME

Conch::Model::DeviceService

=head1 DESCRIPTION

A service represents functionality for a device. 

=cut

package Conch::Model::DeviceService;

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


sub _build_serializable_attributes {[qw[
	id
	name
	created
	updated
]]}



=back

=head1 METHODS

=head2 from_id

	my $service = Conch::Model::DeviceService->from_id($uuid);

Returns a DeviceService given an existing UUID.

=cut

sub from_id ($class, $uuid) {
	$class->_from(id => $uuid);
}



=head2 from_name

	my $service = Conch::Model::DeviceService->from_name($name);

Returns a DeviceService given an existing name

=cut

sub from_name ($class, $name) {
	$class->_from(name => $name);
}


sub _from ($class, $key, $value) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select(
			'device_service', 
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

	my @services = Conch::Model::DeviceService->all()->@*;

Returns an arrayref of all services

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select(
			'device_service',
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

	$service->save();

Create or update the service in the database.

Returns C<$self>

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	$self->_set_updated(Conch::Time->now);

	my %fields = $self->%*;
	delete $fields{id};
	for my $k (qw(created updated)) {
		if ($fields{$k}) {
			$fields{$k} = $fields{$k}->timestamptz;
		}
	}

	my $ret;
	try {
		if($self->id) {
			$ret = $db->update(
				'device_service',
				\%fields,
				{ id => $self->id },
				{ returning => [qw(id created updated)] }
			)->hash;
		} else {
			$ret = $db->insert(
				'device_service',
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

Deletes the service from the database. This is B<permanent> and B<cannot> be
undone.

=cut

sub burn ($self) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->delete('device_service', { 
			id => $self->id,
		});
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->burn: $_");
		return undef;
	};

	return undef;
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

