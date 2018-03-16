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
use Types::Standard qw(Num InstanceOf Str Bool);
use Types::UUID qw(Uuid);

use Role::Tiny::With;

with "Conch::Orc::Role::But";

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

Conch::Time. Cannot be written by user. Is set to C<<Conch::Time->now>> whenever
C<save> is called.

=cut

has 'updated' => (
	is  => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item deactivated

Boolean. Defaults to 0

=cut

has 'deactivated' => (
	is      => 'rw',
	isa     => Bool,
	default => 0,
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

=item steps

Arrayref of all C<Workflow::Step>s associated with this workflow.

Read-only. Lazy loaded.

=cut

has 'steps' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		Conch::Orc::Workflow::Step->many_from_workflow(shift);
	},
);

=back

=head1 METHODS

=head2 from_id

Load a Workflow by its UUID

=cut

sub from_id ($class, $id) {
	return $class->_from(id => $id);
}


=head2 from_name

Load a workflow by its name

=cut

sub from_name ($class, $name) {
	return $class->_from(name => $name);
}


sub _from ($class, $key, $value) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select('workflow', undef, {
			$key => $value
		})->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->_from: $_");
		return undef;
	};

	return undef unless $ret;

	return $class->new(
		id          => $ret->{id},
		locked      => $ret->{locked},
		name        => $ret->{name},
		version     => $ret->{version},
		preflight   => $ret->{preflight},
		created     => Conch::Time->new($ret->{created}),
		updated     => Conch::Time->new($ret->{updated}),
		deactivated => $ret->{deactivated},
	);
}


=head2 all

Returns an arrayref containing all Workflows

=cut

sub all ($class) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select('workflow', undef, undef )->hashes;
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
		$class->new($s);
	} $ret->@*;

	return \@many;
}


=head2 save

Save or update a Workflow in the database.

Returns C<$self>, allowing for method chaining

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	$self->_set_updated(Conch::Time->now);
	my %fields = (
		deactivated => $self->deactivated,
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
	$self->clear_steps();

	if($self->steps->@*) {
		my $last = $self->steps->[-1];
		my $order = $last->order + 1;
		$step->order( $order );
	} else {
		$step->order( 0 );
	}
	$step->save();

	$self->clear_steps();
	return $self;
}


=head2 remove_step

	$workflow->remove_step($step);

Remove any step from the Workflow. The other steps in the Workflow will be
reordered. The removed Step will be marked as deactivated and its C<<->save>>
method called.

Returns C<$self>, allowing for method chaining.

=cut

sub remove_step ($self, $step) {
	$self->clear_steps();

	my @steps = $self->steps->@*;

	my $found = 0;
	for(my $i = 0; $i < @steps; $i++) {
		if ($steps[$i]->id eq $step->id) {
			$found = 1;
		} elsif($found) {
			$steps[$i]->order( $steps[$i]->order - 1);
			$steps[$i]->save();
		}
	}

	$step->deactivated(1);
	$step->save;
	$self->clear_steps();
	return $self;
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
		created     => $self->created->to_string,
		updated     => $self->updated->to_string,
		preflight   => $self->preflight,
		steps       => [],
	}
}



=head2 v2_cascade

Returns a hashref, representing the Workflow in the v2 data set.

This representation B<does> contain the steps, as per their C<<< ->v2 >>>
method.

=cut

sub v2_cascade ($self) {
	$self->clear_steps;
	my @steps = map { $_->v2 } $self->steps->@*;

	my $base = $self->v2;
	$base->{steps} = \@steps;
	return $base;
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

