=head1 NAME

Conch::Orc::Workflow::Step::Status

=head1 DESCRIPTION

A Step::Status represents the active status of a device's execution of the
particular Step.

=cut

package Conch::Orc::Workflow::Step::Status;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Num ArrayRef Bool Str Enum HashRef InstanceOf);
use Types::UUID qw(Uuid);

use Mojo::JSON;

use Conch::Pg;
use Conch::Orc;


=head1 CONSTANTS

=head2 Status

Current state of step. Values correspond to the C<e_workflow_step_state>
database enum.

=over 4

=item COMPLETE

=item PROCESSING

=item STARTED

=back

=cut

use constant {
	COMPLETE   => 'complete',
	PROCESSING => 'processing',
	STARTED    => 'started',
};


=head2 Validation

Current state of validating the provided status dat. Values correspond to the
C<e_workflow_validation_status> database enum.

=over 4

=item VALIDATION_ERROR

=item VALIDATION_FAIL

=item VALIDATION_NOOP

=item VALIDATION_PASS

=item VALIDATION_WIP

=cut

use constant {
	VALIDATION_ERROR => 'error',
	VALIDATION_FAIL  => 'fail',
	VALIDATION_NOOP  => 'noop',
	VALIDATION_PASS  => 'pass',
	VALIDATION_WIP   => 'processing',
};

=back

=head1 ACCESSORS

=over 4

=item id

UUID. Cannot be written by user

=cut

has 'id' => (
	is  => 'rwp',
	isa => Uuid,
);


=item created

Conch::Time. Cannot be written by user.

=cut 

has 'created' => (
	is  => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item updated

Conch::Time. Cannot be written by user. Set to C<<< Conch::Time->now >>>
whenever C<save> is called.

=cut

has 'updated' => (
	is  => 'rwp',
	isa => InstanceOf["Conch::Time"]
);


=item device_id

String. Required. FK'd into C<device(id)>

=cut

has 'device_id' => (
	is       => 'rw',
	isa      => Str,
	required => 1,
);


=item device

Conch::Model::Device. Lazy loaded from C<device_id>

=cut

has 'device' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		my $self = shift;
		return Conch::Model::Device->lookup(
			Conch::Pg->new(),
			$self->device_id
		);
	},
);


=item workflow_step_id

UUID. Required. FK'd into C<workflow_step(id)>

=cut

has 'workflow_step_id' => (
	is       => 'rw',
	isa      => Uuid,
	required => 1,
);


=item workflow_step

Conch::Orc::Workflow::Step. Lazy loaded from C<workflow_step_id>

=cut

has 'workflow_step' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		Conch::Orc::Workflow::Step->from_id(shift->workflow_step_id);
	},
);


=item state

The current state. Values from the State constants listed above. Defaults to
PROCESSING

=cut

has 'state' => (
	default => PROCESSING,
	is      => 'rw',
	isa     => Enum[STARTED, PROCESSING, COMPLETE],
);


=item retry_count

Number. Required. Represents the amount of times the step has been retried

=cut

has 'retry_count' => (
	default  => 1,
	is       => 'rw',
	isa      => Num,
	required => 1,
);


=item validation_status

The current status of validation processing. Values from the Validation
constants listed above. Defaults to VALIDATION_NOOP

=cut

has 'validation_status' => (
	default  => VALIDATION_NOOP,
	is       => 'rw',
	isa      => Enum[
		VALIDATION_ERROR,
		VALIDATION_FAIL,
		VALIDATION_NOOP,
		VALIDATION_PASS,
		VALIDATION_WIP,
	],
	required => 1,
);


=item validation_result_id

UUID

=cut

has 'validation_result_id' => (
	is  => 'rw',
	isa => Uuid,
	# required => 1,
);


=item validation_result

Currently returns undef

=cut

has 'validation_result' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		return undef; # XXX
	},
);

=item force_retry

Boolean. Defaults to 0

=cut

has 'force_retry' => (
	default => 0,
	is      => 'rw',
	isa     => Bool,
);


=item overridden

Booleaon. Defaults to 0

=cut

has 'overridden' => (
	default => 0,
	is      => 'rw',
	isa     => Bool,
);



=item data

Hashref. Defaults to {}

=cut

has 'data' => (
	default => sub { {} },
	is      => 'rw',
	isa     => HashRef,
);


=back

=head1 METHODS

=head2 from_id

Load up a Status by its UUID

=cut


sub from_id ($class, $uuid) {
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->select('workflow_step_status', undef, { 
			id => $uuid
		})->expand->hash;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->from_id: $_");
		return undef;
	};

	return $class->new(
		created              => Conch::Time->new($ret->{created}),
		data                 => $ret->{data},
		device_id            => $ret->{device_id},
		force_retry          => $ret->{force_retry},
		id                   => $ret->{id},
		overridden           => $ret->{overridden},
		retry_count          => $ret->{retry_count},
		state                => $ret->{state},
		updated              => Conch::Time->new($ret->{updated}),
		validation_result_id => $ret->{validation_result_id},
		validation_status    => $ret->{validation_status},
		workflow_step_id     => $ret->{workflow_step_id},
	);

}

=head2 save

Save or update the Status

Returns C<$self>, allowing for method chaining

=cut

sub save ($self) {
	my $db = Conch::Pg->new()->db;

	my $tx = $db->begin;
	my $ret;
	my %fields = (
		data                 => Mojo::JSON::to_json($self->{data}),
		device_id            => $self->{device_id},
		force_retry          => $self->{force_retry},
		overridden           => $self->{overridden},
		retry_count          => $self->{retry_count},
		state                => $self->{state},
		updated              => Conch::Time->now->timestamptz,
		validation_result_id => $self->{validation_result_id},
		validation_status    => $self->{validation_status},
		workflow_step_id     => $self->{workflow_step_id},

	);
	try {
		if($self->id) {
			$ret = $db->update(
				'workflow_step_status',
				\%fields,
				{ id => $self->id }, 
				{ returning => [qw(id created updated)]}
			)->expand->hash;
		} else {
			$ret = $db->insert(
				'workflow_step_status',
				\%fields,
				{ returning => [qw(id created updated)] }
			)->expand->hash;
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

=head2 many_from_execution

	my $ex = Conch::Orc::Workflow::Execution->new(...);
	my $many = Conch::Orc::Workflow::Step::Status->many_from_execution($ex);

Returns an arrayref that contains all the Step::Statuses associated with a
given Execution, ordered by updated timestamp.

=cut

sub many_from_execution ($class, $ex) {
	my $ret;
	try {
		my @step_ids = map { $_->id } $ex->workflow->steps->@*;
		$ret = Conch::Pg->new()->db->select('workflow_step_status', undef, { 
			device_id        => $ex->device->id,
			workflow_step_id => { -in => \@step_ids },
		})->expand->hashes;
	} catch {
		Mojo::Exception->throw(__PACKAGE__."->many_from_execution: $_");
		return undef;
	};

	unless (scalar $ret->@*) {
		return [];
	}

	my @many = sort {
		$a->updated cmp $b->updated
	} map {
		my $s = $_;
		$s->{created} = Conch::Time->new($s->{created});
		$s->{updated} = Conch::Time->new($s->{updated});
		$class->new($s);
	} $ret->@*;
	return \@many;
}


=head2 latest_from_execution

	my $ex = Conch::Orc::Workflow::Execution->new(...);
	my $status = Conch::Orc::Workflow::Step::Status->latest_from_execution($ex);

Returns the most recent Step::Status associated with an Execution

=cut

sub latest_from_execution ($class, $ex) {
	# XXX Turn this into a db query
	return $class->many_from_execution($ex)->[-1];
}


=head2 v2

Returns a hashref, representing a Step::Status in the v2 format

=cut

sub v2 ($self) {
	{
		created              => $self->{created}->to_string(),
		data                 => $self->{data},
		device_id            => $self->{device_id},
		force_retry          => $self->{force_retry},
		id                   => $self->{id},
		overridden           => $self->{overridden},
		retry_count          => $self->{retry_count},
		state                => $self->{state},
		updated              => $self->{updated}->to_string(),
		validation_result_id => $self->{validation_result_id},
		validation_status    => $self->{validation_status},
		workflow_step_id     => $self->{workflow_step_id},
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

