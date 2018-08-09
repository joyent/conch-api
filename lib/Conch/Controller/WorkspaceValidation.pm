=pod

=head1 NAME

Conch::Controller::WorkspaceValidation

=head1 METHODS

=cut

package Conch::Controller::WorkspaceValidation;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;
use List::Util qw(notall any);

with 'Conch::Role::MojoLog';

=head2 workspace_validation_states

Get a list of latest validation states with results for all devices in a workspace

=cut

sub workspace_validation_states ($c) {
	my @statuses;
	@statuses = map { lc($_) } split /,\s*/, $c->param('status')
		if $c->param('status');
	if (
		@statuses
		&& notall {
			my $a = $_;
			any { $_ eq $a } qw( pass fail error )
		}
		@statuses
		)
	{
		$c->log->debug("Status params of ".$c->param('status') ." contains something other than 'pass', 'fail', or 'error'");
		return $c->status(400 => {
			error => "'status' query parameter must be any of 'pass', 'fail', or 'error'."
		});
	}

	my $validation_state_groups =
		Conch::Model::ValidationState->latest_completed_grouped_states_for_workspace(
			$c->stash('workspace_id'),
			@statuses
		);

	my @output = map {
		{ $_->{state}->TO_JSON->%*, results => $_->{results} };
	} @$validation_state_groups;

	$c->log->debug("Found ".scalar(@output)." records");

	$c->status( 200, \@output );
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
