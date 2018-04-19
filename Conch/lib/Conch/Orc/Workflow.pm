=head1 NAME

Conch::Orc::Workflow

=head1 DESCRIPTION

A Workflow represents a set of reusable steps, a script of sorts. Workflows are
a linear process with no ability to parallelize steps.

=cut

package Conch::Orc::Workflow;

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


=item preflight

Boolean. Defaults to 0

This governs if the workflow is used to validate a device for preflight

=cut

has 'preflight' => (
	is      => 'rw',
	isa     => Bool,
	default => 0,
);


=back

=head1 METHODS

=head2 steps

Arrayref of all C<Workflow::Step>s associated with this workflow.

=cut

has 'steps' => (
	is      => 'rwp',
	isa     => ArrayRef,
	default => sub { [] },
);


sub _build_serializable_attributes {[qw[
	id
	name
	created
	updated
	locked
	preflight
	steps
]]}

=head2 steps_as_objects

Returns an array ref of Workflow::Step objects, using the IDs found in the
C<steps> attribute

=cut

sub steps_as_objects ($self) {
	return Conch::Orc::Workflow::Step->many_from_ids($self->steps);
}

sub _refresh_steps ($self) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(qq|
			select id from workflow_step
			where workflow_id = ?
			order by step_order
		|, $self->id)->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->_refresh_steps: $_");
		return undef;
	};

	if($ret) {
		my @steps = map { $_->{id} } $ret->@*;
		$self->_set_steps(\@steps);
	}

	return $self;
}

=head2 from_id

Load a Workflow by its UUID

=cut

sub from_id ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(qq|
			select w.*, array(
				select ws.id
				from workflow_step ws
				where ws.workflow_id = w.id
				order by ws.step_order
			) as steps
			from workflow w
			where w.id = ?;
		|, $id)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_id: $_");
		return undef;
	};

	return undef unless $ret;

	return $class->new(_fixup_timestamptzs($ret)->%*);
}

=head2 from_name

Load a Workflow by its name

=cut

sub from_name ($class, $id) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(qq|
			select w.*, array(
				select ws.id
				from workflow_step ws
				where ws.workflow_id = w.id
				order by ws.step_order
			) as steps
			from workflow w
			where w.name = ?;
		|, $id)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_name: $_");
		return undef;
	};

	return undef unless $ret;

	return $class->new(_fixup_timestamptzs($ret)->%*);
}



=head2 all

Returns an arrayref containing all Workflows

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new->db->query(qq|
			select w.*, array(
				select ws.id
				from workflow_step ws
				where ws.workflow_id = w.id
				order by ws.step_order
			) as steps
			from workflow w;
		|)->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->all: $_");
		return undef;
	};

	return [] unless scalar $ret->@*;

	my @many = map {
		$class->new(_fixup_timestamptzs($_)->%*);
	} $ret->@*;

	return \@many;
}


=head2 save

Save or update a Workflow in the database. Steps are B<not> saved this way. See
C<add_step> and C<remove_step>

Returns C<$self>, allowing for method chaining

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my %fields = (
		locked      => $self->locked,
		name        => $self->name,
		updated     => 'NOW()',
		preflight   => $self->preflight,
	);

	my $ret;
	try {
		if($self->id) {
			$ret = $db->update(
				'workflow',
				\%fields,
				{ id => $self->id },
				{ returning => [qw(id created updated)] }
			)->hash;
		} else {
			$ret = $db->insert(
				'workflow',
				\%fields,
				{ returning => [qw(id created updated)] }
			)->hash;
		}
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->save: $_");
		return undef;
	};

	$ret = _fixup_timestamptzs($ret);
	$self->_set_created($ret->{created});
	$self->_set_updated($ret->{updated});

	$self->_set_id($ret->{id});
	
	return $self;
}

#############################

=head2 add_step

	$workflow->add_step($step);

Append a C<Conch::Orc::Workflow::Step> to the Workflow. 

The step's order attribute will be set to the appropriate value for the
Workflow. The step will also have its C<<->save>> method called.

Does nothing if C<locked> is true.

Returns C<$self>, allowing for method chaining.

=cut

sub add_step ($self, $step) {
	return $self if $self->locked;

	my @steps = $self->_refresh_steps->steps_as_objects->@*;
	if(@steps) {
		my $last = $steps[-1];
		my $order = $last->order + 1;
		$step->order( $order );
	} else {
		$step->order( 0 );
	}
	$step->save();

	return $self->_refresh_steps;
}


=head2 remove_step

	$workflow->remove_step($step);

Remove any step from the Workflow. If the step is found in the workflow, the
other steps in the Workflow will be reordered and the provided step will be
C<burn>ed, removing it from the database entirely.

Does nothing if C<locked> is true.

Returns C<$self>, allowing for method chaining.

=cut


sub remove_step ($self, $step) {
	return $self if $self->locked;

	my @steps = $self->_refresh_steps->steps_as_objects->@*;

	my $found = 0;
	for(my $i = 0; $i < @steps; $i++) {
		if ($steps[$i]->id eq $step->id) {
			$found = 1;
		} elsif($found) {
			$steps[$i]->order( $steps[$i]->order - 1);
			$steps[$i]->save();
		}
	}

	if($found) {
		$step->burn;
	}
	return $self->_refresh_steps;
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

