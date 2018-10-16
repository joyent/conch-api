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
  my $nb = shift; # secured, under /netbox
  # GET /netbox/ipmi/a12345
  $nb->get('/ipmi/:device_id')->to('netbox#getIPMI');
  # GET /netbox/<netbox api path>
  $nb->get('/dcim/:path')->to('netbox#getDCIM');
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
