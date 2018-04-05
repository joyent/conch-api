=head1 NAME

Conch::Controller::Orc::Workflows

=head1 METHODS

=cut

package Conch::Controller::Orc::Workflows;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Orc;


=head2 get_all

Get all workflows, in their entirety

=cut

sub get_all ($c) {
	$c->status_with_validation(200,
		Workflows => Conch::Orc::Workflow->all()
	);
}


=head2 get_one

Get a single workflow, in its entirety

=cut

sub get_one ($c) {
	my $w = Conch::Orc::Workflow->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $w;
	return $c->status(404 => { error => "Not found" }) if $w->deactivated;

	$c->status_with_validation(200, Workflow => $w);
}

=head2 create

Create a new Workflow

=cut

sub create ($c) {
	my $body = $c->validate_input('WorkflowCreate') or return;

	my $w = Conch::Orc::Workflow->new($body->%*)->save();
	$c->status(303 => "/o/workflow/".$w->id);
}


=head2 update

Update an existing Workflow

=cut

sub update ($c) {
	my $w = Conch::Orc::Workflow->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $w;
	return $c->status(404 => { error => "Not found" }) if $w->deactivated;
	my $body = $c->validate_input('WorkflowUpdate') or return;

	if($body->{name} and ($body->{name} ne $w->name)) {
		if(Conch::Orc::Workflow->from_name($body->{name})) {
			return $c->status(400 => { 
				error => "A workflow named '".$body->{name}." already exists" 
			});
		}
	}

	$w->update($body->%*)->save;
	$c->status(303 => "/o/workflow/".$w->id);
}


=head2 delete

"Delete" a workflow by marking it as deactivated

=cut

sub delete ($c) {
	my $w = Conch::Orc::Workflow->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $w;
	return $c->status(404 => { error => "Not found" }) if $w->deactivated;

	$w->update(deactivated => Conch::Time->now)->save;
	return $c->status(204); 
}


=head2 create_step

Create a Workflow::Step tied to an existing Workflow

=cut

sub create_step ($c) {
	my $w = Conch::Orc::Workflow->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $w;
	return $c->status(404 => { error => "Not found" }) if $w->deactivated;

	my $body = $c->req->json;
	if($body->{id}) {
		return $c->status(400 => { error => "'id' parameter not allowed'"});
	}

	for my $k (qw(name validation_plan_id)) {
		return $c->status(400 => {
			error => "'$k' parameter required"
		}) unless $body->{$k};
	}

	# XXX verify validation_plan_id

	$body->{workflow_id} = $w->id;
	my $s = Conch::Orc::Workflow::Step->new($body->%*);
	$w->add_step($s);

	$c->status(303 => "/o/step/".$s->id);
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

