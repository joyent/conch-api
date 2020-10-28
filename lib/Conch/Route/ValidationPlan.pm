package Conch::Route::ValidationPlan;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::ValidationPlan

=head1 METHODS

=head2 routes

Sets up the routes for /validation_plan.

=cut

sub routes {
    my $class = shift;
    my $vp = shift; # secured, under /validation_plan

    $vp->to({ controller => 'validation_plan' });

    # GET /validation_plan
    $vp->get('/')->to('#get_all');

    {
        my $with_plan = $vp->under('/:validation_plan_id_or_name')->to('#find_validation_plan');

        # GET /validation_plan/:validation_plan_id_or_name
        $with_plan->get('/')->to('#get');

        # GET /validation_plan/:validation_plan_id_or_name/validation
        $with_plan->get('/validation')->to('#get_validations');
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

=item * Response: F<response.yaml#/definitions/ValidationPlans>

=back

=head2 C<GET /validation_plan/:validation_plan_id_or_name>

=over 4

=item * Controller/Action: L<Conch::Controller::ValidationPlan/get>

=item * Response: F<response.yaml#/definitions/ValidationPlan>

=back

=head2 C<GET /validation_plan/:validation_plan_id_or_name/validation>

=over 4

=item * Controller/Action: L<Conch::Controller::ValidationPlan/validations>

=item * Response: F<response.yaml#/definitions/LegacyValidations>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
