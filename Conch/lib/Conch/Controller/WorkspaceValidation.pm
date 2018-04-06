=pod

=head1 NAME

Conch::Controller::WorkspaceValidation

=head1 METHODS

=cut

package Conch::Controller::WorkspaceValidation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;

=head2 workspace_validation_states

Get a list of latest validation states with results for all devices in a workspace

=cut

sub workspace_validation_states ($c) {
	my $workspace_devices = Conch::Model::WorkspaceDevice->new->list(
		$c->stash('current_workspace')->id );

	my $validation_states =
		Conch::Model::ValidationState->latest_completed_states_for_devices(
		[ map { $_->id } @$workspace_devices ] );

	my $validation_state_groups =
		Conch::Model::ValidationResult->grouped_by_validation_states(
		$validation_states);

	my @output = map {
		{ $_->{state}->TO_JSON->%*, results => $_->{results} };
	} @$validation_state_groups;

	$c->status( 200, \@output );
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
