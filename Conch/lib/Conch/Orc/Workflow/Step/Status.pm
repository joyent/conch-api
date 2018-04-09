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
use Types::Standard qw(Num ArrayRef Bool Str Enum HashRef InstanceOf Undef);
use Types::UUID qw(Uuid);

use Mojo::JSON;

use Conch::Pg;
use Conch::Orc;

with "Conch::Role::But";
with "Moo::Role::ToJSON";
with "Conch::Role::Timestamps";

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


=item device_id

String. Required. FK'd into C<device(id)>

=cut

has 'device_id' => (
	is       => 'rw',
	isa      => Str,
	required => 1,
);


=item device

Conch::Model::Device. Loaded from C<device_id>

=cut

sub device ($self) {
	return Conch::Model::Device->lookup($self->device_id);
}

=item workflow_step_id

UUID. Required. FK'd into C<workflow_step(id)>

=cut

has 'workflow_step_id' => (
	is       => 'rw',
	isa      => Uuid,
	required => 1,
);


=item workflow_step

Conch::Orc::Workflow::Step. Loaded from C<workflow_step_id>

=cut

sub workflow_step ($self) {
	return Conch::Orc::Workflow::Step->from_id($self->workflow_step_id);
}


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


=item validation_state_id

UUID. FK'd into C<validation_state(id)>

=cut

has 'validation_state_id' => (
	is  => 'rw',
	isa => Uuid | Undef,
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

sub _build_serializable_attributes {[qw[
	created
	data
	device_id
	force_retry
	id
	overridden
	retry_count
	state
	updated
	validation_state_id
	validation_status
	workflow_step_id
]]};


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

	return undef unless $ret;
	return $class->new(_fixup_timestamptzs($ret)->%*);
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
		updated              => 'NOW()',
		validation_state_id  => $self->{validation_state_id},
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

	$ret = _fixup_timestamptzs($ret);
	$self->_set_created($ret->{created});
	$self->_set_updated($ret->{updated});

	$self->_set_id($ret->{id});
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

