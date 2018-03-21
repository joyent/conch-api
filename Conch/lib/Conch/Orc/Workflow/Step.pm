=head1 NAME

Conch::Orc::Workflow::Step

=head1 DESCRIPTION

Represents a single step in a Workflow

=cut

package Conch::Orc::Workflow::Step;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use experimental qw(signatures);

use Type::Tiny;
use Types::Standard qw(Num Bool Str InstanceOf Undef);
use Types::UUID qw(Uuid);

use Role::Tiny::With;
with "Conch::Role::But";

use Conch::Pg;
use Conch::Orc;

use Try::Tiny;


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


=item workflow

A C<Conch::Orc::Workflow> object, loaded from C<workflow_id>

=cut


sub workflow ($self) {
	return Conch::Orc::Workflow->from_id($self->workflow_id);
}


=item name

String. Required.

=cut

has 'name' => (
	is       => 'rw',
	isa      => Str,
	required => 1,
);


=item order

Number. Defaults to 0. Represents the order in which a step will be executed,
counting from 0.

=cut 

has 'order' => (
	is       => 'rw',
	isa      => Num,
	default  => 0,
);


=item retry

Boolean. Defaults to 0. Represents if this step can be retried.

=cut

has 'retry' => (
	is      => 'rw',
	isa     => Bool,
	default => 0,
);


=item max_retries

Number. Defaults to 1. Represents the amount of times this step can be retried,
if C<retry> is sset to true.

=cut

has 'max_retries' => (
	is      => 'rw',
	isa     => Num,
	default => 1,
);


=item validation_plan_id

UUID. Required. 

=cut

has 'validation_plan_id' => (
	is       => 'rw',
	isa      => Uuid,
	required => 1,
);


=item validation_plan

Currently returns undef

=cut

sub validation_plan ($self) {
	return undef; #XXX
}

=item created

Conch::Time. Cannot be set by the user

=cut

has 'created' => (
	is  => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item updated

Conch::Time. Cannot be set by the user. Will be set to C<<< Conch::Time->now >>>
whenever C<save> is called.

=cut

has 'updated' => (
	is  => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item deactivated

Conch::Time

=cut

has 'deactivated' => (
	is  => 'rw',
	isa => InstanceOf["Conch::Time"] | Undef
);


=back

=head1 METHODS

=head2 from_id

Load a Step by its UUID

=cut

sub from_id ($class, $uuid) {
	return $class->_from(id => $uuid);
}

=head2 from_name

Load a Step by its string name

=cut

sub from_name ($class, $name) {
	return $class->_from(name => $name);
}


sub _from ($class, $key, $value) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select('workflow_step', undef, { 
			$key => $value
		})->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_id: $_");
		return undef;
	};

	return undef unless $ret;

	for my $k (qw(created updated deactivated)) {
		if ($ret->{$k}) {
			$ret->{$k} = Conch::Time->new($ret->{$k});
		}
	}
	$ret->{order} = $ret->{step_order};

	return $class->new($ret->%*);
}

=head2 many_from_ids

	my @many = Conch::Orc::Workflow::Steps->many_from_ids(\@list)->@*;

Returns an array ref of Workflow::Step objects, given a list of object UUIDs

=cut

sub many_from_ids ($class, $ids) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->select('workflow_step', undef, {
			id => { -in => $ids }
		})->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->many_from_ids: $_");
		return undef;
	};

	unless (scalar $ret->@*) {
		return [];
	}

	my @many = map {
		my $s = $_;
		$s->{created}     = Conch::Time->new($s->{created});
		$s->{updated}     = Conch::Time->new($s->{updated});
		$s->{order}       = $s->{step_order};
		if($s->{deactivated}) {
			$s->{deactivated} = Conch::Time->new($s->{deactivated});
		}
		$class->new($s);
	} $ret->@*;

	return \@many;

}


=head2 many_from_workflow

	my $w = Conch::Orc::Workflow->from_name('wat');
	my $many = Conch::Orc::Workflow::Step->many_from_workflow($w);

Returns an arrayref containing all the Steps associated with a workflow, sorted
by order

=cut

sub many_from_workflow ($class, $workflow) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select('workflow_step', undef, { 
			workflow_id => $workflow->id,
			deactivated => undef,
		}, { -asc => 'step_order' })->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->many_from_workflow: $_");
		return undef;
	};

	unless (scalar $ret->@*) {
		return [];
	}

	my @many = map {
		my $s = $_;
		$s->{created}     = Conch::Time->new($s->{created});
		$s->{updated}     = Conch::Time->new($s->{updated});
		$s->{order}       = $s->{step_order};
		if($s->{deactivated}) {
			$s->{deactivated} = Conch::Time->new($s->{deactivate});
		}
		$class->new($s);
	} $ret->@*;

	return \@many;
}


=head2 save

Save or update the Step

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my $tx = $db->begin;
	my $ret;

	$self->_set_updated(Conch::Time->now);
	my %fields = (
		deactivated        => $self->deactivated ? $self->deactivated->timestamptz : undef,
		updated            => $self->updated->timestamptz,
		max_retries        => $self->max_retries,
		name               => $self->name,
		step_order         => $self->order,
		retry              => $self->retry,
		validation_plan_id => $self->validation_plan_id,
		workflow_id        => $self->workflow_id,
	);
	try {
		if($self->id) {
			$ret = $db->update(
				'workflow_step',
				\%fields,
				{ id => $self->id }, 
				{ returning => [qw(id created updated)]}
			)->hash;
		} else {
			$ret = $db->insert(
				'workflow_step', 
				\%fields,
				{ returning => [qw(id created updated)] }
			)->hash;
		}
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->save: $_");
		return undef;
	};
	$tx->commit;

	$self->_set_id($ret->{id});
	$self->_set_created(Conch::Time->new($ret->{created}));
	$self->_set_updated(Conch::Time->new($ret->{updated}));

	return $self;
}

=head2 v2

Returns a hashref, representing the Step in v2 format

=cut

sub v2 ($self) {
	{
		created            => $self->created->rfc3339(),
		deactivated        => $self->deactivated ? $self->deactivated->rfc3339 : undef,
		id                 => $self->id,
		max_retries        => $self->max_retries,
		name               => $self->name,
		order              => $self->order,
		retry              => $self->retry,
		updated            => $self->updated->rfc3339(),
		validation_plan_id => $self->validation_plan_id,
		workflow_id        => $self->workflow_id,
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

