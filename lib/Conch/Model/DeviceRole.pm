=head1 NAME

Conch::Model::DeviceRole

=head1 DESCRIPTION

A Device Role is a combination of a hardware product and a list of services
that the box will perform. This identifies the server's "role" in the
ecosystems.

=cut

package Conch::Model::DeviceRole;

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

use List::MoreUtils::XS qw(uniq bremove qsort);

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


=item hardware_product_id

UUID. Required. FK'd to C<hardware_product(id)>

=cut

has 'hardware_product_id' => (
	is => 'rw',
	isa => Uuid,
	required => 1,
);


=item services

ArrayRef containing the IDs of services bound to this Role

=cut

has 'services' => (
	is => 'rwp',
	isa => ArrayRef,
	default => sub { [] },
);


=item description

Optional string describing this role

=cut

has 'description' => (
	is      => 'rw',
	isa     => Str | Undef,
	default => sub { "" }
);


sub _build_serializable_attributes { [qw[
	id
	hardware_product_id
	services
	created
	updated
	description
]] }




=back

=head1 METHODS

=head2 from_id

	my $role = Conch::Model::DeviceRole->from_id($uuid);

Returns a DeviceRole given an existing uuid

=cut

sub from_id ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(q|
			select r.*, array(
				select drs.service_id
				from device_role_services drs
				where drs.role_id = r.id
				order by drs.service_id
			) as services
			from device_role r
			where r.id = ?
				and r.deactivated is null
		|, $id)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_id: $_");
		return undef;
	};

	return undef unless $ret;
	return $class->new(_fixup_timestamptzs($ret)->%*);
}


=head2 all

	my @many = Conch::Model::DeviceRole->all()->@*;

Return all DeviceRoles

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(q|
			select r.*, array(
				select drs.service_id
				from device_role_services drs
				where drs.role_id = r.id
				order by drs.service_id
			) as services
			from device_role r
			where r.deactivated is null
		|)->hashes;
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



=head2 add_service

	$role->add_service($service_uuid);

Add a Service to the Role. If the service already exists in the list, no action
occurs.

Returns C<$self>

=cut


sub add_service ($self, $service_uuid) {
	return $self unless $self->id;
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(q|
			insert into device_role_services(role_id, service_id)
			values( ?, ?)
			on conflict do nothing
		|, $self->id, $service_uuid);
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->add_service: $_");
		return undef;
	};

	my @s = $self->services->@*;

	push @s, $service_uuid;
	qsort { $a cmp $b } @s;
	$self->_set_services([uniq(@s)]);

	return $self;
}


=head2 remove_service

	$role->remove_service($service_uuid);

Removes a Service from the Role.

Returns C<$self>

=cut

sub remove_service ($self, $service_uuid) {
	return $self unless $self->id;
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(q|
			delete from device_role_services
			where role_id = ? and service_id = ?
		|, $self->id, $service_uuid);
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->remove_service: $_");
		return undef;
	};

	my @s = $self->services->@*;
	qsort { $a cmp $b } @s;
	bremove { $_ cmp $service_uuid } @s;
	$self->_set_services(\@s);

	return $self;
}




=head2 save

	$role->save();

Create or update the role in the database.

This B<DOES NOT> update the services list.

Returns C<$self>.

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	$self->_set_updated(Conch::Time->now);

	my %fields = $self->%*;
	delete $fields{id};
	delete $fields{services};
	for my $k (qw(created updated deactivated)) {
		if ($fields{$k}) {
			$fields{$k} = $fields{$k}->timestamptz;
		}
	}

	my $ret;
	try {
		if($self->id) {
			$ret = $db->update(
				'device_role',
				\%fields,
				{ id => $self->id },
				{ returning => [qw(id created updated deactivated)] }
			)->hash;
		} else {
			$ret = $db->insert(
				'device_role',
				\%fields,
				{ returning => [qw(id created updated deactivated)] }
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
	
	if($ret->{deactivated}) {
		$self->deactivated($ret->{deactivated});
	}

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
