package Conch::Controller::ValidationState;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::ValidationState

=head1 DESCRIPTION

Controller for managing Validation states and results.

=head1 METHODS

=head2 get

Get the validation_state record specified by uuid.

Response uses the ValidationStateWithResults json schema.

=cut

sub get ($c) {
    my ($validation_state) = $c->db_validation_states
        ->search({ 'validation_state.id' => $c->stash('validation_state_id') })
        ->prefetch({ validation_state_members => 'validation_result' })
        ->order_by('validation_state_members.result_order')
        ->all;

    if (not $validation_state) {
        $c->log->debug('Failed to find validation for \''.$c->stash('validation_state_id').'\'');
        return $c->status(404);
    }

    $c->log->debug('Found validation '.$validation_state->id);
    return $c->status(200, $validation_state);
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
