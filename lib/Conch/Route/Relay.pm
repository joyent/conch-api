package Conch::Route::Relay;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Relay

=head1 METHODS

=head2 routes

Sets up the routes for /relay:

=cut

sub routes {
    my $class = shift;
    my $relay = shift; # secured, under /relay

    $relay->to({ controller => 'relay' });

    # POST /relay/:relay_serial_number/register
    $relay->post('/:relay_serial_number/register')->to('#register');

    # GET /relay
    $relay->require_system_admin->get('/')->to('#get_all');

    my $with_relay = $relay->under('/:relay_id_or_serial_number')->to('#find_relay');

    # GET /relay/:relay_id_or_serial_number
    $with_relay->get('/')->to('#get');

    # DELETE /relay/:relay_id_or_serial_number
    $with_relay->require_system_admin->delete('/')->to('#delete');
}

1;
__END__

=pod

All routes require authentication.

=head3 C<POST /relay/:relay_serial_number/register>

=over 4

=item * Request: F<request.yaml#/definitions/RegisterRelay>

=item * Response: C<201 CREATED> or C<204 NO CONTENT>, plus Location header

=back

=head3 C<GET /relay>

=over 4

=item * Requires system admin authorization

=item * Response: F<response.yaml#/definitions/Relays>

=back

=head3 C<GET /relay/:relay_id_or_serial_number>

=over 4

=item * Requires system admin authorization, or the user to have previously registered the relay.

=item * Response: F<response.yaml#/definitions/Relay>

=back

=head2 C<DELETE /relay/:relay_id_or_serial_number>

=over 4

=item * Requires system admin authorization

=item * Response: C<204 NO CONTENT>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
