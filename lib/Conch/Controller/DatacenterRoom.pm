package Conch::Controller::DatacenterRoom;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;

with 'Conch::Role::MojoLog';


=head2 under

Handles looking up the object by id or name depending on the url pattern

=cut

sub under ($c) {
	unless($c->is_global_admin) {
		$c->status(403);
		return undef;
	}

	my $s;

	if($c->param('id') =~ /^(.+?)\=(.+)$/) {
		$c->log->warn("Unsupported identifier '$1'");
		$c->status(501);
		return undef;
	} else {
		$c->log->debug("Looking up datacenter room ".$c->param('id'));
		$s = Conch::Model::DatacenterRoom->from_id($c->param('id'));
	}

	if ($s) {
		$c->log->debug("Found datacenter room");
		$c->stash('datacenter_room' => $s);
		return 1;
	} else {
		$c->log->debug("Could not find datacenter room");
		$c->status(404 => { error => "Not found" });
		return undef;
	}

}


=head2 get_all

Get all datacenter rooms

=cut

sub get_all ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $r = Conch::Model::DatacenterRoom->all();
	$c->log->debug("Found ".scalar($r->@*)." datacenter rooms");

	return $c->status(200 => $r);
}


=head2 get_one

Get a single datacenter room

=cut

sub get_one ($c) {
	return $c->status(403) unless $c->is_global_admin;
	$c->status(200, $c->stash('datacenter_room'));
}

=head2 create

Create a new datacenter room

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $i = $c->validate_input('DatacenterRoomCreate');
	if(not $i) {
		$c->log->warn("Input failed validation");
		return;
	}

	my $r = Conch::Model::DatacenterRoom->new($i->%*)->save;
	$c->log->debug("Created datacenter room ".$r->id);
	$c->status(303 => "/room/".$r->id);
}


=head2 update

Update an existing room

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $i = $c->validate_input('DatacenterRoomUpdate');
	if(not $i) {
		$c->log->warn("Input failed validation");
		return;
	}

	$c->stash('datacenter_room')->update($i->%*)->save();
	$c->log->debug("Updated datacenter room ".$c->stash('datacenter_room')->id);
	$c->status(303 => "/room/".$c->stash('datacenter_room')->id);
}


=head2 delete

Permanently delete a datacenter room

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_global_admin;
	$c->stash('datacenter_room')->burn;
	$c->log->debug("Deleted datacenter room ".$c->stash('datacenter_room')->id);
	return $c->status(204);
}


=head2 racks

=cut

sub racks ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $r = Conch::Model::DatacenterRack->from_datacenter_room(
		$c->stash('datacenter_room')->id
	);
	$c->log->debug(
		"Found ".scalar($r->@*).
		" racks for datacenter room ".$c->stash('datacenter_room')->id
	);
	return $c->status(200 => $r);

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
