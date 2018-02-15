=pod

=head1 NAME

Conch::Route::User

=head1 METHODS

=cut

package Conch::Route::User;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw( user_routes);

use DDP;



=head2 user_routes

Sets up routes for the /user namespace

=cut

sub user_routes {
	my $r = shift;

	$r->get('/settings')->to('user#get_settings');
	$r->post('/settings')->to('user#set_settings');

	$r->get('/settings/#key')->to('user#get_setting');
	$r->post('/settings/#key')->to('user#set_setting');
	$r->delete('/settings/#key')->to('user#delete_setting');
}

1;



__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

