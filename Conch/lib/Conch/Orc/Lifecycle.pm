=pod

=head1 NAME

Conch::Orc::Lifecycle

=head1 DESCRIPTION

A 'lifecycle' is an ordered list of 'workflows' for a given hardware product and
device role. 

=cut

package Conch::Orc::Lifecycle;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Num InstanceOf Str Bool Undef ArrayRef);
use Types::UUID qw(Uuid);

use Conch::Time;
use Conch::Pg;
use Conch::Orc;

=head1 ACCESSORS

=over 4

=item id

UUID. Can't be written by user

=cut

has 'id' => (
	is  => 'rwp',
	isa => Uuid,
);


=item name

String. Required

=cut

has 'name' => (
	is       => 'rw',
	isa      => Str,
	required => 1,
);


=item version

Number. Required.

=cut

has 'version' => (
	default  => 1,
	is       => 'rw',
	isa      => Num,
	required => 1,
);


=item created

Conch::Time. Can't be written by user

=cut

has 'created' => (
	is => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item updated

Conch::Time. Can't be written by user. Will be updated to 
C<<< Conch::Time->now >>> whenever C<save> is called.

=cut

has 'updated' => (
	is => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item deactivated

Conch::Time

=cut

has 'deactivated' => (
	is => 'rw',
	isa => InstanceOf["Conch::Time"] | Undef,
	default => undef,
);


=item product_id

UUID. FKs into C<hardware_product(id)>

=cut

has 'product_id' => (
	is       => 'rw',
	isa      => Uuid,
	required => 1,
);


=item locked

Bool. Defaults to 0

=cut

has 'locked' => (
	is      => 'rw',
	isa     => Bool,
	default => 0,
);


=item device_role 

String. Value of C<device(role)>

=cut

has 'device_role' => (
	is       => 'rw',
	isa      => Str,
	required => 1,
);



=item workflows

Arrayref of all Workflows in the Lifecycle

=cut

has 'workflows' => (
	is => 'rwp',
	isa => ArrayRef
	default => sub { [] }
);

=pod

=back

=head1 METHODS

=head2 from_id

Look up a Lifecycle by its UUID. Returns undef if not found

=cut

sub from_id ($class, $uuid) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->query(qq|
			select ol.*, array(
				select olp.workflow_id 
				from orc_lifecycle_plan olp
				where olp.orc_lifecycle_id = ol.id
				order by workflow_order
			) as workflows
			from orc_lifecycle ol
			where ol.id = ?
		|, $uuid)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_id: $_");
		return undef;
	};

	for my $k (qw(created updated deactivated)) {
		if ($ret->{$k}) {
			$ret->{$k} = Conch::Time->new($ret->{$k});
		}
	}

	return $class->new($ret->%*);
}


=head2 many_from_device

	my @lifecycles = Conch::Orc::Lifecycle->many_from_device($d)->@*;

Returns an arrayref containing all Lifecycles for a given device

=cut

sub many_from_device($class, $device) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->query(qq|
			select ol.*, array(
				select olp.workflow_id 
				from orc_lifecycle_plan olp
				where olp.orc_lifecycle_id = ol.id
				order by workflow_order
			) as workflows
			from orc_lifecycle ol
			join orc_lifecycle_plan olp on ol.id = olp.orc_lifecycle_id
			where olp.workflow_id in (
				select distinct(ws.workflow_id)
				from workflow_status ws
				where ws.device_id = ?
			)
		|, $device->id)->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->many_from_device: $_");
		return undef;
	};

	return [] unless $ret;

	my @many = map {
		for my $k (qw(created updated deactivated)) {
			if ($_->{$k}) {
				$_->{$k} = Conch::Time->new($_->{$k});
			}
		}

		$class->new($_->%*)
	} $ret->@*;

	return \@many;
}


=head2 all

Returns an arrayref containing all lifecycles in the database

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->query(qq|
			select ol.*, array(
				select olp.workflow_id 
				from orc_lifecycle_plan olp
				where olp.orc_lifecycle_id = ol.id
				order by olp.workflow_order
			) as workflows
			from orc_lifecycle ol
		|)->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->all: $_");
		return undef;
	};

	my @many = map {
		$_->{created} = Conch::Time->new($_->{created});
		$_->{updated} = Conch::Time->new($_->{updated});
		$class->new($_->%*)
	} $ret->@*;

	return \@many;
}



sub _refresh_workflows ($self) {
	my $db = Conch::Pg->new()->db;
	my $ret = $db->query(qq|
		select workflow_id
		from orc_lifecycle_plan
		where orc_lifecycle_id = ?
		order by workflow_order
	|, $self->id)->hashes;

	my @plan = map { $_->{workflow_id} } $ret->@*;
	$self->_set_workflows(\@plan);
	return $self;
}


=head2 add_workflow

	$lifecycle->add_workflow($workflow);

	$lifecycle->add_workflow($workflow, 2);

Add a new Workflow to the plan. Also takes an optional order number. If
provided, the workflow will be added to that slot and the other Workflows will
be reordered.

Returns C<$self>, allowing for method chaining

=cut

# XXX This doesn't adjust the order of the other workflows in the plan
sub add_workflow($self, $workflow, $order = undef) {
	my $db = Conch::Pg->new->db;

	unless($order) {
		$order = 1;
		my $ret;
		try {
			$ret = $db->query(qq|
				select workflow_order from orc_lifecycle_plan
				where orc_lifecycle_id = ?
				order by workflow_order asc
				limit 1
			|, $self->id)->hash;
		} catch {
			Mojo::Exception->throw(__PACKAGE__."->add_workflow: $_");
			return undef;
		};
		if($ret) {
			$order = $ret->{workflow_order} + 1;
		}
	}

	try {
		$db->insert('orc_lifecycle_plan', {
			orc_lifecycle_id => $self->id,
			workflow_id      => $workflow->id,
			workflow_order   => $order,
		});
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->add_workflow: $_");
		return undef;
	};

	$self->_refresh_workflows;
	return $self;
}


=head2 remove_workflow

	$lifecycle->remove_workflow($workflow);

Remove a workflow from the plan. Remaining workflows will be reordered.

Returns C<$self>, allowing for method chaining.

=cut

sub remove_workflow($self, $workflow) {
	my $db = Conch::Pg->new->db;

	my $plan;
	try {
		$plan = $db->query(qq|
			select * from orc_lifecycle_plan
			where orc_lifecycle_id = ?
			order by workflow_order asc
		|, $self->id)->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->remove_workflow: $_");
		return undef;
	};

	return $self unless $plan->@*;


	my $tx = $db->begin;
	try {
		my $ret = $db->query(qq|
			delete from orc_lifecycle_plan
			where orc_lifecycle_id = ? and workflow_id = ?
		|, $self->id, $workflow->id);

		my $found = 0;
		for my $r ($plan->@*) {
			if ($r->{workflow_id} eq $workflow->id) {
				$found = 1;
				next;
			}
			if ($found) {
				$db->query(qq|
					update orc_lifecycle_plan
					set workflow_order = ?
					where orc_lifecycle_id = ? and workflow_id = ?
				|, ($r->{workflow_order}-1), $self->id, $r->{workflow_id})
			}
		}
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->remove_workflow: $_");
		return undef;
	};
	$tx->commit;
	$self->_refresh_workflows;

	return $self;
}


=head2 save

Save or update the Lifecycle. This does B<not> save the workflow list.

Returns C<$self>, allowing for method chaining

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my $ret;
	my %attrs = (
		name        => $self->name,
		version     => $self->version,
		device_role => $self->device_role,
		product_id  => $self->product_id,
		updated     => Conch::Time->now->timestamptz,
		deactivated => $self->deactivated ? $self->deactivated->timestamptz : undef,
		locked      => $self->locked,
	);
	try {
		if($self->id) {
			$ret = $db->update(
				'orc_lifecycle', 
				\%attrs,
				{ id => $self->id }
			)->hash;
		} else {
			$ret = $db->insert(
				'orc_lifecycle', 
				\%attrs,
				{ returning => [qw(id created updated)] }
			)->hash;
		}
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->save: $_");
		return undef;
	};

	$self->_set_id($ret->{id});
	$self->_set_created(Conch::Time->new($ret->{created}));
	$self->_set_updated(Conch::Time->new($ret->{updated}));

	return $self;
}


=head2 serialize

Returns a hashref, representing the object in a serialized format

=cut

#############################
sub serialize ($self) {
	{
		created     => $self->created->rfc3339,
		deactivated => ($self->deactivated ? $self->deactivated->rfc3339 : undef),
		device_role => $self->device_role,
		product_id  => $self->product_id,
		id          => $self->id,
		locked      => $self->locked,
		name        => $self->name,
		updated     => $self->updated->rfc3339,
		version     => $self->version,
		workflows   => $self->workflows,
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

