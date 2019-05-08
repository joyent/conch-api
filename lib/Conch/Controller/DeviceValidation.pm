package Conch::Controller::DeviceValidation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use List::Util qw(all any);

=pod

=head1 NAME

Conch::Controller::DeviceValidation

=head1 METHODS

=head2 list_validation_states

Get the latest validation states for a device. Accepts the query parameter 'status',
indicating the desired status(es) (comma-separated) to search for -- one or more of:
pass, fail, error.

Response uses the ValidationStatesWithResults json schema.

=cut

sub list_validation_states ($c) {
    my @statuses = split /,/, $c->param('status') // '';
    if (not all { my $status = $_; any { $status eq $_ } qw(pass fail error) } @statuses) {
        $c->log->debug('Status params of '.$c->param('status') ." contains something other than 'pass', 'fail', or 'error'");
        return $c->status(400, {
            error => "'status' query parameter must be any of 'pass', 'fail', or 'error'."
        });
    }

    my @validation_states = $c->stash('device_rs')
        ->search_related('validation_states',
            @statuses ? { 'validation_states.status' => { -in => \@statuses } } : ())
        ->latest_completed_state_per_plan
        ->prefetch({ validation_state_members => 'validation_result' })
        ->all;

    $c->log->debug('Found '.scalar(@validation_states).' records');

    $c->status(200, \@validation_states);
}

=head2 validate

Validate the device against the specified validation.

B<DOES NOT STORE VALIDATION RESULTS>.

This is useful for testing and evaluating Validation Plans against a given
device.

Response uses the ValidationResults json schema.

=cut

sub validate ($c) {
    my $validation_id = $c->stash('validation_id');
    my $validation = $c->db_ro_validations->active->find($validation_id);
    if (not $validation) {
        $c->log->debug('Could not find validation '.$validation_id);
        return $c->status(404);
    }

    my $data = $c->validate_input('DeviceReport');
    if (not $data) {
        $c->log->debug('Device report input failed validation');
        return;
    }

    my @validation_results = Conch::ValidationSystem->new(
        schema => $c->ro_schema,
        log => $c->log,
    )->run_validation(
        validation => $validation,
        device => $c->db_ro_devices->active->find($c->stash('device_id')),
        data => $data,
    );

    $c->status(200, \@validation_results);
}

=head2 run_validation_plan

Validate the device against the specified Validation Plan.

B<DOES NOT STORE VALIDATION RESULTS>.

This is useful for testing and evaluating Validation Plans against a given
device.

Response uses the ValidationResults json schema.

=cut

sub run_validation_plan ($c) {
    my $validation_plan_id = $c->stash('validation_plan_id');
    my $validation_plan = $c->db_ro_validation_plans->active->find($validation_plan_id);
    if (not $validation_plan) {
        $c->log->debug('Could not find validation plan '.$validation_plan_id);
        return $c->status(404);
    }

    my $data = $c->validate_input('DeviceReport');
    if (not $data) {
        $c->log->debug('Device report input failed validation');
        return;
    }

    my ($status, @validation_results) = Conch::ValidationSystem->new(
        schema => $c->ro_schema,
        log => $c->log,
    )->run_validation_plan(
        validation_plan => $validation_plan,
        device => $c->db_ro_devices->active->find($c->stash('device_id')),
        data => $data,
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
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
