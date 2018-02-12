=head1 NAME

Conch::Orc::Workflow::Execution

=head1 DESCRIPTION

A workflow execution represents a workflow and a device's progress through its
steps.

The object is convenience collection and does not represent a discrete database
component. 

=cut

package Conch::Orc::Workflow::Execution;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo;
use experimental qw(signatures);

use Try::Tiny;
use Type::Tiny;
use Types::Standard qw(Num Str ArrayRef InstanceOf);
use Types::UUID qw(Uuid);

use Conch::Pg;
use Conch::Orc;

use aliased 'Conch::Orc::Workflow::Step::Status' => "StepStatus";
use aliased 'Conch::Orc::Workflow::Step' => "Step";
use aliased 'Conch::Orc::Workflow::Status' => "WorkflowStatus";
use aliased 'Conch::Orc::Workflow' => "Workflow";


=head1 ACCESSORS

=over 4

=item device_id

String. FK'd into C<device(id)>

=cut

has 'device_id' => (
	required => 1,
	is       => 'ro',
	isa      => Str,
);


=item device

Conch::Model::Device. Lazy loaded from C<device_id>

=cut

has 'device' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		return Conch::Model::Device->lookup(
			shift->device_id
		);
	},
);

=item workflow_id

UUID. FK'd into C<workflow(id)>

=cut

has 'workflow_id' => (
	is  => 'ro',
	isa => Uuid,
);


=item workflow

Conch::Orc::Workflow. Lazy loaded from C<workflow_id>

=cut

has 'workflow' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		Workflow->from_id(shift->workflow_id);
	},
);


=item steps_status

Arrayref containing the relevant Step::Status objects, where each Status is
assigned an index based on the Step's order.

Lazy loaded

=cut

has 'steps_status' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		my $self = shift;

		my %status = map {
			$_->workflow_step_id => $_
		} StepStatus->many_from_execution($self)->@*;

		my @ret;
		foreach my $step ($self->workflow->steps->@*) {
			if ($status{$step->id}) {
				$ret[ $step->order - 1 ] = $status{$step->id};
			}
		}
		return \@ret;
	}
);


=item latest_step_status

The most recent Step::Status for the execution. Lazy loaded

=cut

has 'latest_step_status' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		StepStatus->latest_from_execution(shift);
	},
);


=item workflow_status

An arrayref containing all associated Workflow::Status objects. Lazy loaded

=cut

has 'workflow_status' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		WorkflowStatus->many_from_execution(shift)
	},
);


=item latest_workflow_status

Most recent Workflow::Status. Lazy loaded

=cut

has 'latest_workflow_status' => (
	clearer => 1,
	is      => 'lazy',
	builder => sub {
		WorkflowStatus->latest_from_execution(shift)
	},
);


=back

=head1 METHODS

=head2 many_from_device

	my $d = Conch::Model::Device->from_name('wat');
	my $many = Conch::Orc::Workflow::Execution->many_from_device($d);

Returns all Executions associated with a device, as determined by their
workflow statuses.

=cut

sub many_from_device ($class, $device) {
	my @many = map {
		$class->new(
			device_id => $_->device_id,
			workflow_id => $_->workflow_id,
		)
	} Conch::Orc::Workflow::Status->many_from_device($device)->@*;

	return \@many;
}


=head2 latest_from_device

	my $d = Conch::Model::Device->from_name('wat');
	my $ex = Conch::Orc::Workflow::Execution->latest_from_device($d);

Returns a single Execution, which represents the most recent Execution for a
device, as determined by its workflow status.

=cut

sub latest_from_device ($class, $device) {
	my $status = Conch::Orc::Workflow::Status->latest_from_device($device);
	return undef unless $status;

	return $class->new(
		workflow_id => $status->workflow_id,
		device_id   => $status->device_id, 
	);
}


=head2 v1

Returns a hashref representing the Execution in v1 format.

This format includes B<all> workflow and step statuses.

=cut


sub v1 ($self) {
	my @workflow_status = map { $_ ? $_->v1 : undef } $self->workflow_status->@*;
	my @steps_status = map { $_ ? $_->v1 : undef } $self->steps_status->@*;

	return {
		device       => $self->device->as_v1,
		workflow     => $self->workflow->v1_cascade,
		status       => \@workflow_status,
		steps_status => \@steps_status,
	}
}


=head2 v1_latest

Returns a hashref representing the Execution's most recent condition in v1
format.

This format includes B<only> the most recent workflow and step status

=cut

sub v1_latest ($self) {
	my $status = $self->latest_workflow_status ? 
		$self->latest_workflow_status->v1 : undef;

	my $step_status = $self->latest_step_status ?
		$self->latest_step_status->v1 : undef;

	return {
		device       => $self->device->as_v1,
		workflow     => $self->workflow->v1_cascade,
		status       => [ $status ],
		steps_status => [ $step_status ],
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


