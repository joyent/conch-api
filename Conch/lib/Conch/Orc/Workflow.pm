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

use Role::Tiny::With;
with "Conch::Role::But";

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


=item version

Number. Required. Defaults to 1

=cut

has 'version' => (
	default  => 1,
	is       => 'rw',
	isa      => Num,
	required => 1,
);


=item created

Conch::Time. Cannot be written by user.

=cut

has 'created' => (
	is => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item updated

Conch::Time. Cannot be written by user. Is set to C<<< Conch::Time->now >>>
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


=item locked

Boolean. Defaults to 0

=cut

has 'locked' => (
	is      => 'rw',
	isa     => Bool,
	default => 0,
);


=item preflight

Boolean. Defaults to 0

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
			where workflow_id = ? and deactivated is null
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
					and ws.deactivated is null
				order by ws.step_order
			) as steps
			from workflow w
			where w.id = ?;
		|, $id)->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->_from: $_");
		return undef;
	};

	return undef unless $ret;

	if($ret->{deactivated}) {
		$ret->{deactivated} = Conch::Time->new($ret->{deactivated});
	}

	for my $k (qw(created updated deactivated)) {
		if($ret->{$k}) {
			$ret->{$k} = Conch::Time->new($ret->{$k});
		}
	}

	my $s = $class->new($ret->%*);
	return $s;
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
					and ws.deactivated is null
				order by ws.step_order
			) as steps
			from workflow w;
		|)->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->all: $_");
		return undef;
	};

	unless (scalar $ret->@*) {
		return [];
	}
	my @many = map {
		my $s = $_;
		$s->{created} = Conch::Time->new($s->{created});
		$s->{updated} = Conch::Time->new($s->{updated});
		if($s->{deactivated}) {
			$s->{deactivated} = Conch::Time->new($s->{deactivated});
		}
		$class->new($s);
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

	$self->_set_updated(Conch::Time->now);
	my %fields = (
		deactivated => $self->deactivated ? $self->deactivated->timestamptz : undef,
		locked      => $self->locked,
		name        => $self->name,
		updated     => $self->updated->timestamptz,
		preflight   => $self->preflight,
		version     => $self->version,
	);

	my $tx = $db->begin;
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
	$tx->commit;

	$self->_set_id($ret->{id});
	$self->_set_created(Conch::Time->new($ret->{created}));
	$self->_set_updated(Conch::Time->new($ret->{updated}));
	
	return $self;
}

#############################

=head2 add_step

	$workflow->add_step($step);

Append a C<Conch::Orc::Workflow::Step> to the Workflow. 

The step's order attribute will be set to the appropriate value for the
Workflow. The step will also have its C<<->save>> method called.

Returns C<$self>, allowing for method chaining.

=cut

sub add_step ($self, $step) {
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

Remove any step from the Workflow. The other steps in the Workflow will be
reordered. The removed Step will be marked as deactivated and its C<<->save>>
method called.

Returns C<$self>, allowing for method chaining.

=cut


sub remove_step ($self, $step) {
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
		$step->deactivated(Conch::Time->now);
		$step->save;
	}
	return $self->_refresh_steps;
}



=head2 v2

Returns a hashref, representing the Workflow in the v2 data set.

This representation B<does not> contain any steps and the C<step> attribute will
be set to an empty arrayref.

=cut

sub v2 ($self) {
	{
		id          => $self->id,
		name        => $self->name,
		locked      => $self->locked,
		version     => $self->version,
		deactivated => ($self->deactivated ? $self->deactivated->rfc3339 : undef),
		created     => $self->created->rfc3339,
		updated     => $self->updated->rfc3339,
		preflight   => $self->preflight,
		steps       => $self->steps,
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

