=head1 NAME

Conch::Controller::Orc::WorkflowExecutions

=head1 METHODS

=cut

package Conch::Controller::Orc::WorkflowExecutions;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Orc;

=head2 get_active

Get all Executions with a most recent status of ONGOING

=cut

sub get_active ($c) {
	$c->status(200, _build_by_state(Conch::Orc::Workflow::Status->ONGOING));
}

=head2 get_stopped

Get all Executions with a most recent status of STOPPED

=cut

sub get_stopped ($c) {
	$c->status(200, _build_by_state(Conch::Orc::Workflow::Status->STOPPED));
}


=head2 get_completed

Get all Executions with a most recent status of COMPLETED

=cut

sub get_completed ($c) {
	$c->status(200, _build_by_state(Conch::Orc::Workflow::Status->COMPLETED));
}


sub _build_by_state ($state) {
	my $ss = Conch::Orc::Workflow::Status->many_from_latest_status($state);

	my @e;
	foreach my $s ($ss->@*) {
		push @e, Conch::Orc::Workflow::Execution->new(
			device_id => $s->device->id,
			workflow_id => $s->workflow->id,
		)->v2;
	}
	return \@e
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

