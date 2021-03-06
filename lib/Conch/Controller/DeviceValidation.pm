package Conch::Controller::DeviceValidation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::DeviceValidation

=head1 METHODS

=head2 get_validation_state

Get the latest validation state for a device. Accepts the query parameter C<status>,
indicating the desired status(es) to limit the search -- one or more of: pass, fail, error.
e.g. C<?status=pass>, C<?status=error&status=fail>. (If no parameters are provided, all
statuses are searched for.)

Response uses the ValidationStateWithResults json schema.

=cut

sub get_validation_state ($c) {
    my $params = $c->stash('query_params');

    my ($validation_state) = $c->db_validation_states
        ->search({
            device_id => $c->stash('device_id'),
            $params->{status} ? ('validation_state.status' => $params->{status}) : ()
        })
        ->order_by({ -desc => 'validation_state.created' })
        ->rows(1)
        ->as_subselect_rs
        ->with_legacy_validation_results
        ->with_validation_results
        ->all;

    if (not $validation_state) {
        $c->log->debug('No validation states for device');
        return $c->status(404);
    }

    $c->status(200, $validation_state);
}

=head2 validate

Validate the device against the specified validation.

B<DOES NOT STORE VALIDATION RESULTS>.

This is useful for testing and evaluating experimental validations against a given device.

Response uses the LegacyValidationResults json schema.

=cut

sub validate ($c) {
    my $validation_id = $c->stash('validation_id');
    my $validation = $c->db_ro_legacy_validations->active->find($validation_id);
    if (not $validation) {
        $c->log->debug('Could not find validation '.$validation_id);
        return $c->status(404);
    }

    my @validation_results = Conch::LegacyValidationSystem->new(
        schema => $c->ro_schema,
        log => $c->get_logger('validation'),
    )->run_validation(
        validation => $validation,
        device => $c->db_ro_devices->find($c->stash('device_id')),
        data => $c->stash('request_data'),
    );

    $c->status(200, \@validation_results);
}

=head2 run_validation_plan

Validate the device against the specified Validation Plan.

B<DOES NOT STORE VALIDATION RESULTS>.

This is useful for testing and evaluating Validation Plans against a given
device.

Response uses the LegacyValidationResults json schema.

=cut

sub run_validation_plan ($c) {
    my $validation_plan_id = $c->stash('validation_plan_id');
    my $validation_plan = $c->db_ro_legacy_validation_plans->active->find($validation_plan_id);
    if (not $validation_plan) {
        $c->log->debug('Could not find validation plan '.$validation_plan_id);
        return $c->status(404);
    }

    my ($status, @validation_results) = Conch::LegacyValidationSystem->new(
        schema => $c->ro_schema,
        log => $c->get_logger('validation'),
    )->run_validation_plan(
        validation_plan => $validation_plan,
        device => $c->db_ro_devices->find($c->stash('device_id')),
        data => $c->stash('request_data'),
        no_save_db => 1,
    );

    $c->status(200, \@validation_results);
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
# vim: set sts=2 sw=2 et :
