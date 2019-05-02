package Conch::Controller::ValidationPlan;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::Validation

Controller for managing Validation Plans

=head1 METHODS

=head2 create

Create new Validation Plan.

=cut

sub create ($c) {
    return $c->status(403) if not $c->is_system_admin;

    # this endpoint is temporarily (?) disabled
    return $c->status(410);

    my $input = $c->validate_input('CreateValidationPlan');
    return if not $input;

    if (my $existing_validation_plan = $c->db_validation_plans->active->search({ name => $input->{name} })->single) {
        $c->log->debug("Name conflict on '$input->{name}'");
        return $c->status(409, {
            error => "A Validation Plan already exists with the name '$input->{name}'"
        });
    }

    my $validation_plan = $c->db_validation_plans->create($input);

    $c->log->debug('Created validation plan '.$validation_plan->id);

    $c->status(303, '/validation_plan/'.$validation_plan->id);
}

=head2 list

List all available Validation Plans.

Response uses the ValidationPlans json schema.

=cut

sub list ($c) {
    my @validation_plans = $c->db_validation_plans->active->all;
    $c->log->debug('Found '.scalar(@validation_plans).' validation plans');
    $c->status(200, \@validation_plans);
}

=head2 find_validation_plan

Find the Validation Plan specified by uuid or name and put it in the stash as
C<validation_plan>.

=cut

sub find_validation_plan($c) {
    my $identifier = $c->stash('validation_plan_id_or_name');

    my $validation_plan = $c->db_validation_plans->active->search({
        (is_uuid($identifier) ? 'id' : 'name') => $identifier,
    })->single;

    if (not $validation_plan) {
        $c->log->debug("Failed to find validation plan for '$identifier'");
        return $c->status(404);
    }

    $c->log->debug('Found validation plan '.$validation_plan->id);
    $c->stash('validation_plan', $validation_plan);
    return 1;
}

=head2 get

Get the (active) Validation Plan specified by uuid or name.

Response uses the ValidationPlan json schema.

=cut

sub get ($c) {
    return $c->status(200, $c->stash('validation_plan'));
}

=head2 list_validations

List all Validations associated with the Validation Plan, both active and deactivated.

Response uses the Validations json schema.

=cut

sub list_validations ($c) {
    my @validations = $c->stash('validation_plan')->validations;

    $c->log->debug('Found '.scalar(@validations).' validations for validation plan '.$c->stash('validation_plan')->id);

    $c->status(200, \@validations);
}

=head2 add_validation

Add a validation to a validation plan.

=cut

sub add_validation ($c) {
    return $c->status(403) if not $c->is_system_admin;

    # this endpoint is temporarily (?) disabled
    return $c->status(410);

    my $input = $c->validate_input('AddValidationToPlan');
    return if not $input;

    my $validation = $c->db_validations->active->find($input->{id});
    if (not $validation) {
        $c->log->debug("Failed to find validation $input->{id}");
        return $c->status(409, { error => "Validation with ID '$input->{id}' doesn't exist" });
    }

    $c->stash('validation_plan')
        ->find_or_create_related('validation_plan_members', { validation_id => $validation->id });

    $c->log->debug('Added validation '.$validation->id.' to validation plan'.$c->stash('validation_plan')->id);

    $c->status(204);
}

=head2 remove_validation

Remove a Validation associated with the Validation Plan

=cut

sub remove_validation ($c) {
    return $c->status(403) if not $c->is_system_admin;

    # this endpoint is temporarily (?) disabled
    return $c->status(410);

    my $validation_id = $c->stash('validation_id');
    my $validation_plan = $c->stash('validation_plan');
    if (not $validation_plan->search_related('validation_plan_members', { validation_id => $validation_id })) {
        $c->log->debug("Validation with ID '$validation_id' isn't a member of the Validation Plan");
        return $c->status(409, {
            error => "Validation with ID '$validation_id' isn't a member of the Validation Plan"
        });
    }

    $validation_plan->delete_related('validation_plan_members', { validation_id => $validation_id });
    $c->log->debug("Removed validation $validation_id from validation plan".$c->stash('validation_plan')->id);

    $c->status(204);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
