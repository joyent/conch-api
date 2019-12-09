package Conch::Route::Validation;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Validation

=head1 METHODS

=head2 routes

Sets up the routes for /validation, /validation_plan and /validation_state:

=cut

sub routes {
    my $class = shift;
    my $r = shift;  # secured, under /

    # all these /validation routes go to the Validation controller
    my $v = $r->any('/validation');
    $v->to({ controller => 'validation' });

    # GET /validation
    $v->get('/')->to('#list');

    {
        my $with_validation = $v->under('/:validation_id_or_name')->to('#find_validation');

        # GET /validation/:validation_id_or_name
        $with_validation->get('/')->to('#get');
    }


    # all these /validation_plan routes go to the ValidationPlan controller
    my $vp = $r->any('/validation_plan');
    $vp->to({ controller => 'validation_plan' });

    # GET /validation_plan
    $vp->get('/')->to('#list');

    {
        my $with_plan = $vp->under('/:validation_plan_id_or_name')->to('#find_validation_plan');

        # GET /validation_plan/:validation_plan_id_or_name
        $with_plan->get('/')->to('#get');

        # GET /validation_plan/:validation_plan_id_or_name/validation
        $with_plan->get('/validation')->to('#list_validations');
    }

    {
        my $vs = $r->any('/validation_state');
        $vs->to({ controller => 'validation_state' });

        # GET /validation_state/:validation_state_id
        $vs->get('/<validation_state_id:uuid>')->to('#get');
    }
}

1;
__END__

=pod

All routes require authentication.

=head3 C<GET /validation>

=over 4

=item * Response: F<response.yaml#/definitions/Validations>

=back

=head3 C<GET /validation/:validation_id_or_name>

=over 4

=item * Response: F<response.yaml#/definitions/Validation>

=back

=head3 C<GET /validation_plan>

=over 4

=item * Response: F<response.yaml#/definitions/ValidationPlans>

=back

=head3 C<GET /validation_plan/:validation_plan_id_or_name>

=over 4

=item * Response: F<response.yaml#/definitions/ValidationPlan>

=back

=head3 C<GET /validation_plan/:validation_plan_id_or_name/validation>

=over 4

=item * Response: F<response.yaml#/definitions/Validations>

=back

=head3 C<GET /validation_state/:validation_state_id>

=over 4

=item * Response: F<response.yaml#/definitions/ValidationStateWithResults>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
