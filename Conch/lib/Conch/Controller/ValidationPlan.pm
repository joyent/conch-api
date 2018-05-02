=pod

=head1 NAME

Conch::Controller::Validation

Controller for managing Validation Plans

=head1 METHODS

=cut

package Conch::Controller::ValidationPlan;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';
use Conch::Models;

=head2 create

Create new Validation Plan.

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $create_schema = JSON::Validator->new->schema(
		{
			type     => 'object',
			required => [ 'name', 'description' ],
			properties =>
				{ name => { type => 'string' }, description => { type => 'string' } }
		}
	);

	my $body   = $c->req->json;
	my @errors = $create_schema->validate($body);
	return $c->status( 400,
		{ error => "Errors in request body", source => \@errors } )
		if @errors;

	my $existing_validation_plan =
		Conch::Model::ValidationPlan->lookup_by_name( $body->{name} );
	return $c->status(
		409,
		{
			error => "A Validation Plan already exists with the name '$body->{name}'"
		}
	) if $existing_validation_plan;

	my $validation_plan =
		Conch::Model::ValidationPlan->create( $body->{name}, $body->{description} );

	$c->status( 201, $validation_plan );
}

=head2 list

List all available Validation Plans

=cut

sub list ($c) {
	my $validation_plans = Conch::Model::ValidationPlan->list;
	$c->status( 200, $validation_plans );
}

=head2 under

Find the Validation Plan specified by ID and put it in the stash as
C<validation_plan>.

=cut

sub under ($c) {
	my $vp_id = $c->param('id');
	unless ( is_uuid($vp_id) ) {
		$c->status( 400,
			{ error => "Validation Plan ID must be a UUID. Got '$vp_id'." } );
		return 0;
	}
	my $vp = Conch::Model::ValidationPlan->lookup($vp_id);
	if ($vp) {
		$c->stash( validation_plan => $vp );
		return 1;
	}
	else {
		$c->status( 404, { error => "Validation Plan $vp_id not found" } );
		return 0;
	}
}

=head2 get

Get the Validation Plan specified by ID

=cut

sub get ($c) {
	if ( $c->under ) {
		$c->status( 200, $c->stash('validation_plan') );
	}
	else {
		return 0;
	}
}

=head2 list_validations

List all Validations associated with the Validation Plan

=cut

sub list_validations ($c) {
	my $validations = $c->stash('validation_plan')->validations;

	$c->status( 200, $validations );
}

=head2 add_validation

List all Validations associated with the Validation Plan

=cut

sub add_validation ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $add_schema = JSON::Validator->new->schema(
		{
			type       => 'object',
			required   => ['id'],
			properties => { id => { type => 'string' } }
		}
	);

	my $body   = $c->req->json;
	my @errors = $add_schema->validate($body);
	return $c->status( 400,
		{ error => "Errors in request body", source => \@errors } )
		if @errors;

	my $maybe_validation = Conch::Model::Validation->lookup( $body->{id} );
	return $c->status( 409,
		{ error => "Validation with ID '$body->{id}' doesn't exist" } )
		unless $maybe_validation;

	$c->stash('validation_plan')->add_validation($maybe_validation);

	$c->status(204);
}

=head2 remove_validation

Remove a Validation associated with the Validation Plan

=cut

sub remove_validation ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $v_id = $c->param('validation_id');
	unless ( is_uuid($v_id) ) {
		return $c->status( 400,
			{ error => "Validation ID must be a UUID. Got '$v_id'." } );
	}
	my $validation_plan = $c->stash('validation_plan');
	my $is_member = grep /$v_id/, $validation_plan->validation_ids->@*;

	return $c->status(
		409,
		{
			error =>
				"Validation with ID '$v_id' isn't a member of the Validation Plan"
		}
	) unless $is_member;

	$c->stash('validation_plan')->remove_validation($v_id);

	$c->status(204);
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
