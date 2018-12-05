package Conch::Route::Validation;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Validation

=head1 METHODS

=head2 routes

Sets up the routes for /validation and /validation_plan:

    GET     /validation
    POST    /validation_plan
    GET     /validation_plan
    GET     /validation_plan/:validation_plan_id
    GET     /validation_plan/:validation_plan_id/validation
    POST    /validation_plan/:validation_plan_id/validation
    DELETE  /validation_plan/:validation_plan_id/validation/:validation_id

=cut

sub routes {
    my $class = shift;
    my $r = shift;  # secured, under /

    # GET /validation
    $r->get('/validation')->to('validation#list');

    # all these /validation_plan routes go to the ValidationPlan controller
    my $vp = $r->any('/validation_plan');
    $vp->to({ controller => 'validation_plan' });

    # POST /validation_plan
    $vp->post('/')->to('#create');

    # GET /validation_plan
    $vp->get('/')->to('#list');

    {
        my $with_plan = $vp->under('/:validation_plan_id')->to('#find_validation_plan');

        # GET /validation_plan/:validation_plan_id
        $with_plan->get('/')->to('#get');

        # GET /validation_plan/:validation_plan_id/validation
        $with_plan->get('/validation')->to('#list_validations');

        # POST /validation_plan/:validation_plan_id/validation
        $with_plan->post('/validation')->to('#add_validation');

        # DELETE /validation_plan/:validation_plan_id/validation/:validation_id
        $with_plan->delete('/validation/:validation_id')->to('#remove_validation');
    }
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
# vim: set ts=4 sts=4 sw=4 et :
