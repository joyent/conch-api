package Conch::Controller::DatacenterRoom;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;


=head2 under

Handles looking up the object by id or name depending on the url pattern 

=cut

sub under ($c) {
	my $s;

	if($c->param('id') =~ /^(.+?)\=(.+)$/) {
		$c->status(501);
		return undef;
	} else {
		$s = Conch::Model::DatacenterRoom->from_id($c->param('id'));
	}

	if ($s) {
		$c->stash('datacenter_room' => $s);
		return 1;
	} else {
		$c->status(404 => { error => "Not found" });
		return undef;
	}

}


=head2 get_all

Get all datacenter rooms

=cut

sub get_all ($c) {
	return $c->status(200, Conch::Model::DatacenterRoom->all());
}


=head2 get_one

Get a single datacenter room

=cut

sub get_one ($c) {
	$c->status(200, $c->stash('datacenter_room'));
}

=head2 create

Create a new datacenter room

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $i = $c->validate_input('DatacenterRoomCreate') or return;

	my $r = Conch::Model::DatacenterRoom->new($i->%*)->save;
	$c->status(303 => "/room/".$r->id);
}


=head2 update

Update an existing room

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $i = $c->validate_input('DatacenterRoomUpdate') or return;

	$c->stash('datacenter_room')->update($i->%*)->save();
	$c->status(303 => "/room/".$c->stash('datacenter_room')->id);
}


=head2 delete

Permanently delete a datacenter room

=cut

sub delete ($c) {
	$c->stash('datacenter_room')->burn;
	return $c->status(204); 
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

