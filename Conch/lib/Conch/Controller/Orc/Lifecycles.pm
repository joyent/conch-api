=head1 NAME

Conch::Controller::Orc::Lifecycles

=head1 METHODS

=cut

package Conch::Controller::Orc::Lifecycles;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Orc;


=head2 get_all

Get all lifecycles

=cut

sub get_all ($c) {
	return $c->status_with_validation(200, 
		OrcLifecycles => Conch::Orc::Lifecycle->all()
	);
}


=head2 get_one

Get a single lifecycle

=cut

sub get_one ($c) {
	my $l = Conch::Orc::Lifecycle->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $l;

	$c->status_with_validation(200, OrcLifecycle => $l );
}


=head2 create

Create a new lifecycle

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $body = $c->validate_input('OrcLifecycleCreate') or return;

	unless(Conch::Model::DeviceRole->from_id($body->{role_id})) {
		return $c->status_with_validation(400, Error => {
			error => "Role does not exist"
		});
	}

	if(Conch::Orc::Lifecycle->from_role_id($body->{role_id})) {
		return $c->status_with_validation(400, Error => {
			error => "Role is already in use"
		});
	}


	$body->{version} = 0 unless $body->{version};
	if(Conch::Orc::Lifecycle->from_name($body->{name})) {
		return $c->status_with_validation(400, Error => {
			error => "Lifecycle already exists with this name"
		});
	}
	
	my $l = Conch::Orc::Lifecycle->new($body->%*)->save();

	$c->status(303 => "/o/lifecycle/".$l->id);
}

=head2 update

Update an existing lifecycle

=cut

sub update ($c) {
	my $l = Conch::Orc::Lifecycle->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $l;

	my $body = $c->validate_input('OrcLifecycleUpdate') or return;

	if($body->{role_id}) {
		unless(Conch::Model::DeviceRole->from_id($body->{role_id})) {
			return $c->status_with_validation(400, Error => {
				error => "Role does not exist"
			});
		}

		my $lr = Conch::Orc::Lifecycle->from_role_id($body->{role_id});
		if ($lr and ($lr->id ne $l->id)) {
			return $c->status_with_validation(400, Error => {
				error => "Role is already in use"
			});
		}
	}

	$body->{version} = 0 unless $body->{version};
	if($body->{name} and ($body->{name} ne $l->name)) {
		if(Conch::Orc::Lifecycle->from_name($body->{name})) {
			return $c->status_with_validation(400, Error => {
				error => "Lifecycle already exists with this name"
			});
		}
	}

	$l->update($body->%*)->save;
	$c->status(303 => "/o/lifecycle/".$l->id);
}

=head2 add_workflow

Add a workflow to a lifecycle plan, with an optional plan_order 

=cut

sub add_workflow ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $l = Conch::Orc::Lifecycle->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $l;

	my $body = $c->validate_input('OrcLifecycleAddWorkflow') or return;
	
	my $w = Conch::Orc::Workflow->from_id($body->{workflow_id});
	return $c->status(404 => { error => "Workflow not found" }) unless $w;


	if ($body->{plan_order}) {
		$l->add_workflow($w->id, $body->{plan_order});
	} else {
		$l->append_workflow($w->id);
	}
	$c->status(303 => "/o/lifecycle/".$l->id);
}


=head2 remove_workflow

Remove a workflow from a lifecycle plan

=cut

sub remove_workflow ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $l = Conch::Orc::Lifecycle->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $l;

	my $body = $c->validate_input('OrcLifecycleRemoveWorkflow') or return;
	
	my $w = Conch::Orc::Workflow->from_id($body->{workflow_id});
	return $c->status(404 => { error => "Workflow not found" }) unless $w;

	$l->remove_workflow($w->id);

	$c->status(303 => "/o/lifecycle/".$l->id);
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

