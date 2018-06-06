
=pod

=head1 NAME

Conch::Route::Datacenter

=head1 METHODS

=cut

package Conch::Route::Datacenter;
use Mojo::Base -strict;

=head2 routes

Sets up the routes

=cut

sub routes {
	my ($class, $r) = @_;

	my $d = $r->under('/dc');
	$d->get('/')->to("datacenter#get_all");
	$d->post('/')->to("datacenter#create");

	my $i = $d->under('/:id')->to("datacenter#under");
	$i->get('/')->to("datacenter#get_one");
	$i->post('/')->to("datacenter#update");
	$i->delete('/')->to("datacenter#delete");
	$i->get('/rooms')->to("datacenter#get_rooms");

	######
	$r->get('/room')->to("datacenter_room#get_all");
	$r->post('/room')->to("datacenter_room#create");

	my $roi = $r->under('/room/:id')->to("datacenter_room#under");
	$roi->get('/')->to("datacenter_room#get_one");
	$roi->post('/')->to("datacenter_room#update");
	$roi->delete('/')->to("datacenter_room#delete");

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
