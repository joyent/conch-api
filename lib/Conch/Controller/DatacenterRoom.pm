package Conch::Controller::DatacenterRoom;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;


with 'Conch::Role::MojoLog';


=head2 find_datacenter_room

Handles looking up the object by id or name depending on the url pattern

=cut

sub find_datacenter_room ($c) {
	unless($c->is_system_admin) {
		$c->status(403);
		return undef;
	}

	if ($c->stash('datacenter_room_id_or_name') =~ /^(.+?)\=(.+)$/) {
		$c->log->warn("Unsupported identifier '$1'");
		return $c->status(501);
	}

	$c->log->debug("Looking up datacenter room ".$c->stash('datacenter_room_id_or_name'));
	my $room = $c->db_datacenter_rooms->find($c->stash('datacenter_room_id_or_name'));

	if (not $room) {
		$c->log->debug("Could not find datacenter room");
		return $c->status(404 => { error => "Not found" });
	}

	$c->log->debug("Found datacenter room");
	$c->stash('datacenter_room' => $room);
	return 1;
}


=head2 get_all

Get all datacenter rooms

Response uses the DatacenterRoomsDetailed json schema.

=cut

sub get_all ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my @rooms = $c->db_datacenter_rooms->all;
	$c->log->debug('Found ' . scalar(@rooms) . ' datacenter rooms');

	return $c->status(200 => \@rooms);
}


=head2 get_one

Get a single datacenter room

Response uses the DatacenterRoomDetailed json schema.

=cut

sub get_one ($c) {
	return $c->status(403) unless $c->is_system_admin;
	$c->status(200, $c->stash('datacenter_room'));
}

=head2 create

Create a new datacenter room

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_system_admin;
	my $input = $c->validate_input('DatacenterRoomCreate');
	return if not $input;

	$input->{datacenter_id} = delete $input->{datacenter} if exists $input->{datacenter};

	my $room = $c->db_datacenter_rooms->create($input);
	$c->log->debug("Created datacenter room ".$room->id);
	$c->status(303 => '/room/'.$room->id);
}


=head2 update

Update an existing room

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_system_admin;
	my $input = $c->validate_input('DatacenterRoomUpdate');
	return if not $input;

	$input->{datacenter_id} = delete $input->{datacenter} if exists $input->{datacenter};

	$c->stash('datacenter_room')->update({ %$input, updated => \'NOW()' });
	$c->log->debug("Updated datacenter room ".$c->stash('datacenter_room_id_or_name'));
	$c->status(303 => "/room/".$c->stash('datacenter_room')->id);
}


=head2 delete

Permanently delete a datacenter room.

Also removes the room from all workspaces.

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_system_admin;
	# FIXME: if we have cascade_copy => 1 set on this rel,
	# then we don't have to do this... and we don't have to worry about rack updates either.
	# But for now, we have a dangling reference to the deleted room in datacenter_rack!
	$c->stash('datacenter_room')->delete_related('workspace_datacenter_rooms');
	$c->stash('datacenter_room')->delete;
	$c->log->debug("Deleted datacenter room ".$c->stash('datacenter_room')->id);
	return $c->status(204);
}


=head2 racks

=cut

sub racks ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my @racks = $c->db_datacenter_racks->search({ datacenter_room_id => $c->stash('datacenter_room')->id });
	$c->log->debug(
		"Found ".scalar(@racks).
		" racks for datacenter room ".$c->stash('datacenter_room')->id
	);
	return $c->status(200 => \@racks);

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
