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

    # POST /relay/:relay_id/register
    $relay->post('/:relay_id/register')->to('#register');

    # GET /relay
    $relay->get('/')->to('#list');

    # DELETE /relay/:relay_serial_number
    $relay->require_system_admin->delete('/:relay_serial_number')->to('#delete');
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<POST /relay/:relay_id/register>

=over 4

=item * Request: input.yaml#/RegisterRelay

=item * Response: C<204 NO CONTENT>

=back

=cut

=head3 C<GET /relay>

=over 4

=item * Requires System Admin Authentication

=item * Response: response.yaml#/Relays

=back

=cut

=head2 C<DELETE /relay/:relay_serial_number>

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
