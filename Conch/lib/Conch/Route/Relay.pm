=pod

=head1 NAME

Conch::Route::Relay

=head1 METHODS

=cut

package Conch::Route::Relay;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw( relay_routes);

use DDP;



=head2 relay_routes

Set up the routes for /relay

=cut

sub relay_routes {
	my $r = shift;

	$r->post('/relay/:id/register')->to('relay#register');
	$r->get('/relay')->to('relay#list');
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

