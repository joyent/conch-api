=head1 NAME

Conch::Orc::Lifecycle

=head1 DESCRIPTION

A Lifecycle is a list of Workflows to execute for a given device role.

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
use Types::Standard qw(Num Str Bool ArrayRef);
use Types::UUID qw(Uuid);
use List::MoreUtils qw(uniq);

with "Conch::Role::But";
with "Moo::Role::ToJSON";
with "Conch::Role::Timestamps";

use Conch::Time;
use Conch::Pg;
use Conch::Orc;


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



=item locked

Boolean. Defaults to 0

This governs if steps can be added or removed from the workflow.

=cut

has 'locked' => (
	is      => 'rw',
	isa     => Bool,
	default => 0,
);


=item role_id

UUID. FK'd into C<device_role(id)>. Required.

=cut

has 'role_id' => (
	is       => 'rw',
	isa      => Uuid,
	required => 1,
);


=item plan

Arrayref of Workflow IDs, orderd by the C<plan_order> field. Cannot be written
by user.

=cut

has 'plan' => (
	is => 'rwp',
	isa => ArrayRef,
	default => sub { [] },
);

sub _build_serializable_attributes { [qw[
	id
	created
	updated
	name
	locked
	role_id
	plan
]] }



=head1 METHODS

=head2 from_id

Load a Lifecycle by its UUID

=cut

sub from_id ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(qq|
			select l.*, array(
				select wlp.workflow_id
				from workflow_lifecycle_plan wlp
				where wlp.lifecycle_id = l.id
				order by wlp.plan_order
			) as plan
			from workflow_lifecycle l
			where l.id = ?;
		|, $id)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_id: $_");
		return undef;
	};

	return undef unless $ret;
	return $class->new(_fixup_timestamptzs($ret)->%*);
}


=head2 from_name

Load a Lifecycle for by name

=cut

sub from_name ($class, $name) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(qq|
			select l.*, array(
				select wlp.workflow_id
				from workflow_lifecycle_plan wlp
				where wlp.lifecycle_id = l.id
				order by wlp.plan_order
			) as plan
			from workflow_lifecycle l
			where l.name = ?
		|, $name)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_name: $_");
		return undef;
	};

	return undef unless $ret;
	return $class->new(_fixup_timestamptzs($ret)->%*);
}


=head2 all

Returns an arrayref containing all active Lifecycles

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(qq|
			select l.*, array(
				select wlp.workflow_id
				from workflow_lifecycle_plan wlp
				where wlp.lifecycle_id = l.id
				order by wlp.plan_order
			) as plan
			from workflow_lifecycle l
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


=head2 save

Save or update a Lifecycle in the database. The plan is B<not> saved this way.

Returns C<$self>

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my %fields = $self->%*;
	delete @fields{ qw(id plan created updated) };
	$fields{updated} = 'NOW()';

	my $ret;
	try {
		if($self->id) {
			$ret = $db->update(
				'workflow_lifecycle',
				\%fields,
				{ id => $self->id },
				{ returning => [qw(id created updated)] }
			)->hash;
		} else {
			$ret = $db->insert(
				'workflow_lifecycle',
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
	$self->_set_created(Conch::Time->new($ret->{created}));
	$self->_set_updated(Conch::Time->new($ret->{updated}));
	return $self;
}

=head2 append_workflow

	$lifecycle->append_workflow($workflow->id);

Append a workflow UUID to the lifecycle's plan. Does nothing if the lifecycle
has not been saved (lacks an ID).

A unique constraint exists on the lifecycle id and workflow id, meaning that a
workflow can only exist in a lifecycle's plan a single time. If an
C<append_workflow> call attempts to add a duplicate workflow id to the
plan, the plan will remain unchanged.

=cut

sub append_workflow ($self, $workflow_uuid) {
	return $self unless $self->id;

	my @plan = $self->plan->@*;

	my @found = grep { $_ eq $workflow_uuid } @plan;
	if(@found) {
		return $self;
	}

	push @plan, $workflow_uuid;
	$self->_set_plan(\@plan);

	return $self->_rebuild_plan;
}

=head2 add_workflow

	$lifecycle->add_workflow($workflow->id, 2);

Add a workflow UUID to the lifecycle's plan at the position indicated. The
position numeral is an array index and starts counting at 0.

A unique constraint exists on the lifecycle id and workflow id, meaning that a
workflow can only exist in a lifecycle's plan a single time. If an
C<add_workflow> call attempts to add a duplicate workflow id to the
plan, the plan will remain unchanged.

=cut

sub add_workflow ($self, $workflow_uuid, $order) {
	my @p = $self->plan->@*;

	my @found = grep { $_ eq $workflow_uuid } @p;
	if(@found) {
		return $self;
	}

	my @new_plan;
	foreach my $idx (0 .. $#p) {
		if ($idx == $order) {
			push @new_plan, $workflow_uuid;
		}
		push @new_plan, $p[$idx];
	}

	$self->_set_plan(\@new_plan);

	return $self->_rebuild_plan;
}

=head2 remove_workflow

	$lifecycle->remove_workflow($workflow->id);

Removes all occurences of a workflow UUID in the lifecycle's plan. Does nothing
if the lifecycle has not been saved (lacks an ID).

=cut

sub remove_workflow ($self, $workflow_uuid) {
	return $self unless $self->id;

	my @p = $self->plan->@*;

	my @found = grep { $_ eq $workflow_uuid } @p;
	unless(@found) {
		return $self;
	}


	my @new_plan;
	foreach my $idx (0 .. $#p) {
		unless ($p[$idx] eq $workflow_uuid) {
			push @new_plan, $p[$idx];
		}
	}
	$self->_set_plan(\@new_plan);

	return $self->_rebuild_plan;
}


# Blows away the existing join records and recreates them using the array 
# indices on ->plan as the plan_order field
sub _rebuild_plan ($self) {
	return $self unless $self->id;
	my $db = Conch::Pg->new->db;
	my $tx = $db->begin;

	my @p = uniq($self->plan->@*);


	try {
		$db->query(qq|
			delete from workflow_lifecycle_plan
			where lifecycle_id = ?
		|, $self->id);

		foreach my $idx (0 .. $#p) {
			my $id = $p[$idx] or next;
			$db->insert('workflow_lifecycle_plan', {
				lifecycle_id => $self->id,
				workflow_id  => $id,
				plan_order   => $idx,
			});
		}
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->_rebuild_plan: $_");
		return undef;
	};
	$tx->commit;

	return $self->_refresh_plan;
}

# Refreshes the ->plan attribute
sub _refresh_plan ($self) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(qq|
			select wlp.workflow_id
			from workflow_lifecycle_plan wlp
			where wlp.lifecycle_id = ?
			order by wlp.plan_order
		|, $self->id)->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->_refresh_plan: $_");
		return undef;
	};

	return [] unless $ret and $ret->@*;

	my @many = map {
		$_->{workflow_id}
	} $ret->@*;

	$self->_set_plan(\@many);
	return $self;
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

