=head1 NAME

Conch::Controller::Orc::WorkflowSteps

=head1 METHODS

=cut

package Conch::Controller::Orc::WorkflowSteps;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Orc;


=head2 get_one

Get a single Workflow::Step by its UUID

=cut

sub get_one ($c) {
	my $s = Conch::Orc::Workflow::Step->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(200, $s->v2);
}


=head2 update

Update an existing Workflow::Step.

B<NOTE:> workflow_id and order cannot be updated this way

=cut

sub update ($c) {
	my $s = Conch::Orc::Workflow::Step->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;

	my $body = $c->req->json;
	delete $body->{id};
	delete $body->{workflow_id};
	delete $body->{order};

	$c->status(200, $s->update($body->%*)->save->v2);
}

=head2 delete

Delete an existing Workflow::Step

=cut

sub delete ($c) {
	my $s = Conch::Orc::Workflow::Step->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;

	my $w = $s->workflow;
	$s->workflow->remove_step($s);

	return $c->status(204);
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

