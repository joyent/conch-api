package Conch::Controller::DatacenterRoom;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::DatacenterRoom

=head1 METHODS

=head2 find_datacenter_room

Handles looking up the object by id or alias.

=cut

sub find_datacenter_room ($c) {
    my $identifier = $c->stash('datacenter_room_id_or_alias');
    my $rs = $c->db_datacenter_rooms;
    if (is_uuid($identifier)) {
        $c->stash('datacenter_room_id', $identifier);
        $rs = $rs->search({ 'datacenter_room.id' => $identifier });
    }
    else {
        $c->stash('datacenter_room_alias', $identifier);
        $rs = $rs->search({ 'datacenter_room.alias' => $identifier });
    }

    $c->log->debug('Looking up datacenter room '.$identifier);
    my $room = $rs->single;

    if (not $room) {
        $c->log->debug('Could not find datacenter room');
        return $c->status(404);
    }

    $c->log->debug('Found datacenter room');
    $c->stash('datacenter_room', $room);
    return 1;
}

=head2 get_all

Get all datacenter rooms.

Response uses the DatacenterRoomsDetailed json schema.

=cut

sub get_all ($c) {
    my @rooms = $c->db_datacenter_rooms->order_by('alias')->all;
    $c->log->debug('Found '.scalar(@rooms).' datacenter rooms');

    return $c->status(200, \@rooms);
}

=head2 get_one

Get a single datacenter room.

Response uses the DatacenterRoomDetailed json schema.

=cut

sub get_one ($c) {
    $c->status(200, $c->stash('datacenter_room'));
}

=head2 create

Create a new datacenter room.

=cut

sub create ($c) {
    my $input = $c->validate_request('DatacenterRoomCreate');
    return if not $input;

    my $room = $c->db_datacenter_rooms->create($input);
    $c->log->debug('Created datacenter room '.$room->id);
    $c->status(303, '/room/'.$room->id);
}

=head2 update

Update an existing room.

=cut

sub update ($c) {
    my $input = $c->validate_request('DatacenterRoomUpdate');
    return if not $input;

    $c->stash('datacenter_room')->update({ $input->%*, updated => \'now()' });
    $c->log->debug('Updated datacenter room '.$c->stash('datacenter_room_id_or_alias'));
    $c->status(303, '/room/'.$c->stash('datacenter_room')->id);
}

=head2 delete

Permanently delete a datacenter room.

=cut

sub delete ($c) {
    if ($c->stash('datacenter_room')->related_resultset('racks')->exists) {
        $c->log->debug('Cannot delete datacenter_room: in use by one or more racks');
        return $c->status(409, { error => 'cannot delete a datacenter_room when a rack is referencing it' });
    }

    $c->stash('datacenter_room')->delete;
    $c->log->debug('Deleted datacenter room '.$c->stash('datacenter_room')->id);
    return $c->status(204);
}

=head2 racks

Response uses the Racks json schema.

=cut

sub racks ($c) {
    my @racks = $c->stash('datacenter_room')->related_resultset('racks')->all;
    $c->log->debug('Found '.scalar(@racks).' racks for datacenter room '.$c->stash('datacenter_room_id_or_alias'));
    return $c->status(200, \@racks);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut

1;
# vim: set ts=4 sts=4 sw=4 et :
