package Conch::Controller::ValidationPlan;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::ValidationPlan

Controller for managing Validation Plans

=head1 METHODS

=head2 get_all

List all available Validation Plans.

Response uses the LegacyValidationPlans json schema.

=cut

sub get_all ($c) {
    my @validation_plans = $c->db_validation_plans->active->order_by('name')->all;
    $c->log->debug('Found '.scalar(@validation_plans).' validation plans');
    $c->status(200, \@validation_plans);
}

=head2 find_validation_plan

Chainable action that uses the C<legacy_validation_plan_id_or_name> provided in the stash
(usually via the request URL) to look up a validation_plan, and stashes the result in
C<legacy_validation_plan>.

=cut

sub find_validation_plan($c) {
    my $identifier = $c->stash('legacy_validation_plan_id_or_name');

    my $validation_plan = $c->db_validation_plans->active->search({
        (is_uuid($identifier) ? 'id' : 'name') => $identifier,
    })->single;

    if (not $validation_plan) {
        $c->log->debug('Could not find validation plan '.$identifier);
        return $c->status(404);
    }

    $c->log->debug('Found validation plan '.$validation_plan->id);
    $c->stash('legacy_validation_plan', $validation_plan);
    return 1;
}

=head2 get

Get the (active) Validation Plan specified by uuid or name.

Response uses the LegacyValidationPlan json schema.

=cut

sub get ($c) {
    return $c->status(200, $c->stash('legacy_validation_plan'));
}

=head2 get_validations

List all Validations associated with the Validation Plan, both active and deactivated.

Response uses the LegacyValidations json schema.

=cut

sub get_validations ($c) {
    my @validations = $c->stash('legacy_validation_plan')
        ->related_resultset('validation_plan_members')
        ->related_resultset('validation')
        ->order_by([ 'validation.name', 'validation.version' ])
        ->all;

    $c->log->debug('Found '.scalar(@validations).' validations for validation plan '.$c->stash('legacy_validation_plan')->id);

    $c->status(200, \@validations);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
