package Conch::Route::ValidationPlan;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::ValidationPlan

=head1 METHODS

=head2 routes

Sets up the routes for /validation_plan.

All routes are B<deprecated> and will be removed in Conch API v4.0.

=cut

sub routes {
    my $class = shift;
    my $vp = shift; # secured, under /validation_plan

    $vp->to(controller => 'validation_plan', deprecated => 'v4.0');

    # GET /validation_plan
    $vp->get('/')->to('#get_all', response_schema => 'LegacyValidationPlans');

    {
        my $with_plan = $vp->under('/:legacy_validation_plan_id_or_name')->to('#find_validation_plan');

        # GET /validation_plan/:legacy_validation_plan_id_or_name
        $with_plan->get('/')->to('#get', response_schema => 'LegacyValidationPlan');

        # GET /validation_plan/:legacy_validation_plan_id_or_name/validation
        $with_plan->get('/validation')->to('#get_validations', response_schema => 'LegacyValidations');
    }
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /validation_plan>

=over 4

=item * Controller/Action: L<Conch::Controller::ValidationPlan/get_all>

=item * Response: F<response.yaml#/$defs/LegacyValidationPlans>

=back

=head2 C<GET /validation_plan/:legacy_validation_plan_id_or_name>

=over 4

=item * Controller/Action: L<Conch::Controller::ValidationPlan/get>

=item * Response: F<response.yaml#/$defs/LegacyValidationPlan>

=back

=head2 C<GET /validation_plan/:legacy_validation_plan_id_or_name/validation>

=over 4

=item * Controller/Action: L<Conch::Controller::ValidationPlan/validations>

=item * Response: F<response.yaml#/$defs/LegacyValidations>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
