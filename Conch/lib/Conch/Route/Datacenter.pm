
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
	$roi->get('/racks')->to("datacenter_room#racks");

	######
	$r->get('/rack_role')->to("datacenter_rack_role#get_all");
	$r->post('/rack_role')->to("datacenter_rack_role#create");

	my $rr = $r->under('/rack_role/:id')->to("datacenter_rack_role#under");
	$rr->get('/')->to("datacenter_rack_role#get");
	$rr->post('/')->to("datacenter_rack_role#update");
	$rr->delete('/')->to("datacenter_rack_role#delete");

	######
	$r->get('/rack')->to("datacenter_rack#get_all");
	$r->post('/rack')->to("datacenter_rack#create");

	$rr = $r->under('/rack/:id')->to("datacenter_rack#under");
	$rr->get('/')->to("datacenter_rack#get");
	$rr->post('/')->to("datacenter_rack#update");
	$rr->delete('/')->to("datacenter_rack#delete");
	$rr->get('/layouts')->to("datacenter_rack#layouts");


	######
	$r->get('/layout')->to("datacenter_rack_layout#get_all");
	$r->post('/layout')->to("datacenter_rack_layout#create");

	$rr = $r->under('/layout/:id')->to("datacenter_rack_layout#under");
	$rr->get('/')->to("datacenter_rack_layout#get");
	$rr->post('/')->to("datacenter_rack_layout#update");
	$rr->delete('/')->to("datacenter_rack_layout#delete");

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
