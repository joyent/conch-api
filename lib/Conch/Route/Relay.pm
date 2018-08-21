package Conch::Route::Relay;

use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw(relay_routes);

=pod

=head1 NAME

Conch::Route::Relay

=head1 METHODS

=head2 relay_routes

Set up the routes for /relay:

    POST  /relay/:relay_id/register
    GET   /relay

=cut

sub relay_routes {
    my $relay = shift; # secured, under /relay

    # POST /relay/:relay_id/register
    $relay->post('/:relay_id/register')->to('relay#register');

    # GET /relay
    $relay->get('/')->to('relay#list');
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
