package Conch::Route::ValidationState;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::ValidationState

=head1 METHODS

=head2 routes

Sets up the routes for /validation_state.

=cut

sub routes {
    my $class = shift;
    my $vs = shift; # secured, under /validation_state

    $vs->to({ controller => 'validation_state' });

    # GET /validation_state/:validation_state_id
    $vs->get('/<validation_state_id:uuid>')->to('#get', response_schema => 'ValidationStateWithResults');
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /validation_state/:validation_state_id>

=over 4

=item * Controller/Action: L<Conch::Controller::ValidationState/get>

=item * Response: F<response.yaml#/$defs/ValidationStateWithResults>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
