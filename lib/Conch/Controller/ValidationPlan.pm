=pod

=head1 NAME

Conch::Controller::Validation

Controller for managing Validation Plans

=head1 METHODS

=cut

package Conch::Controller::ValidationPlan;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';
use Conch::Models;

with 'Conch::Role::MojoLog';

=head2 create

Create new Validation Plan.

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my $body = $c->validate_input("CreateValidationPlan");
	if(not $body) {
		$c->log->warn("Input failed validation");
		return;
	}

	my $existing_validation_plan =
		Conch::Model::ValidationPlan->lookup_by_name( $body->{name} );

	if($existing_validation_plan) {
		$c->log->debug("Name conflict on '".$body->{name}."'");
		return $c->status( 409 => {
			error => "A Validation Plan already exists with the name '$body->{name}'"
		});
	}	

	my $validation_plan =
		Conch::Model::ValidationPlan->create( $body->{name}, $body->{description} );

	$c->log->debug("Created validation plan ".$validation_plan->id);

	$c->status(303 => "/validation_plan/".$validation_plan->id);
}

=head2 list

List all available Validation Plans

=cut

sub list ($c) {
	my $validation_plans = Conch::Model::ValidationPlan->list;
	$c->log->debug("Found ".scalar($validation_plans->@*)." validation plans");
	$c->status( 200, $validation_plans );
}

=head2 find_validation_plan

Find the Validation Plan specified by ID and put it in the stash as
C<validation_plan>.

=cut

sub find_validation_plan($c) {
	my $vp_id = $c->stash('validation_plan_id');
	unless ( is_uuid($vp_id) ) {
		$c->log->warn("ID is not a UUID");
		$c->status( 400, {
			error => "Validation Plan ID must be a UUID. Got '$vp_id'."
		});
		return 0;
	}
	my $vp = Conch::Model::ValidationPlan->lookup($vp_id);
	if ($vp) {
		$c->log->debug("Found validation plan ".$vp->id);
		$c->stash( validation_plan => $vp );
		return 1;
	} else {
		$c->log->debug("Failed to find validation plan $vp_id");
		$c->status( 404, { error => "Validation Plan $vp_id not found" } );
		return 0;
	}
}

=head2 get

Get the Validation Plan specified by ID

=cut

sub get ($c) {
	return $c->status( 200, $c->stash('validation_plan') );
}

=head2 list_validations

List all Validations associated with the Validation Plan

=cut

sub list_validations ($c) {
	my $validations = $c->stash('validation_plan')->validations;

	$c->log->debug(
		"Found ".scalar($validations->@*).
		" validations for validation plan ".
		$c->stash('validation_plan')->id
	);

	$c->status( 200, $validations );
}

=head2 add_validation

List all Validations associated with the Validation Plan

=cut

sub add_validation ($c) {
	return $c->status(403) unless $c->is_system_admin;
	my $body = $c->validate_input("AddValidationToPlan");
	if(not $body) {
		$c->log->warn("Input failed validation");
		return;
	}

	my $maybe_validation = Conch::Model::Validation->lookup( $body->{id} );
	unless($maybe_validation) {
		$c->log->debug("Failed to find validation ".$body->{id});
		return $c->status( 409 => {
			error => "Validation with ID '$body->{id}' doesn't exist"
		});
	}

	$c->stash('validation_plan')->add_validation($maybe_validation);

	$c->log->debug(
		"Added validation ".$maybe_validation->id." to validation plan".
		$c->stash('validation_plan')->id
	);

	$c->status(204);
}

=head2 remove_validation

Remove a Validation associated with the Validation Plan

=cut

sub remove_validation ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my $v_id = $c->stash('validation_id');
	unless ( is_uuid($v_id) ) {
		$c->log->warn("ID is not a UUID");
		return $c->status( 400 => {
			error => "Validation ID must be a UUID. Got '$v_id'."
		});
	}

	my $validation_plan = $c->stash('validation_plan');
	my $is_member = grep /$v_id/, $validation_plan->validation_ids->@*;

	unless($is_member) {
		$c->log->debug("Validation with ID '$v_id' isn't a member of the Validation Plan");
		return $c->status(409 => {
			error => "Validation with ID '$v_id' isn't a member of the Validation Plan"
		});
	}

	$c->stash('validation_plan')->remove_validation($v_id);
	$c->log->debug(
		"Removed validation $v_id from validation plan".
		$c->stash('validation_plan')->id
	);

	$c->status(204);
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
