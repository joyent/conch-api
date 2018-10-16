package Conch::Route::Netbox;

use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw(netbox_routes);

=pod

=head1 NAME

Conch::Route::Netbox

=head1 METHODS

=head2 netbox_routes

Sets up the routes for /netbox:
    GET     /netbox/:device_id
    GET     /netbox/:device_id/interfaces/:int_name

=cut

sub netbox_routes {
  my $nb = shift; # secured, under /relay
  # GET /netbox/devices/?device_id=a12345
  $nb->get('/devices')->to('netbox#getDevices');
  # GET /netbox/interfaces/?device_id=a12345&name=ipmi1&mac_address=11:22:11:22:11
  $nb->get('/interfaces')->to('netbox#getInterfaces');
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
