package Conch::Controller::DatacenterRoom;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::DatacenterRoom

=head1 METHODS

=head2 find_datacenter_room

Chainable action that uses the C<datacenter_room_id_or_alias> value provided in the stash
(usually via the request URL) to look up a datacenter_room, and stashes the result in
C<datacenter_room>.

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
        $c->log->debug('Could not find datacenter room '.$identifier);
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

    return $c->status(409, { error => 'Datacenter does not exist' })
        if not $c->db_datacenters->search({ id => $input->{datacenter_id} })->exists;

    return $c->status(409, { error => 'a room already exists with that alias' })
        if $c->db_datacenter_rooms->search({ alias => $input->{alias} })->exists;

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

    return $c->status(409, { error => 'Datacenter does not exist' })
        if $input->{datacenter_id}
            and not $c->db_datacenters->search({ id => $input->{datacenter_id} })->exists;

    my $room = $c->stash('datacenter_room');

    return $c->status(409, { error => 'a room already exists with that alias' })
        if $input->{alias} and $input->{alias} ne $room->alias
            and $c->db_datacenter_rooms->search({ alias => $input->{alias} })->exists;

    $room->update({ $input->%*, updated => \'now()' });
    $c->log->debug('Updated datacenter room '.$c->stash('datacenter_room_id_or_alias'));
    $c->status(303, '/room/'.$room->id);
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

=head2 find_rack

Response uses the Rack json schema.

=cut

sub find_rack ($c) {
    my $rack_rs = $c->stash('datacenter_room')
        ->related_resultset('racks')
        ->search({ name => $c->stash('rack_name') });

    if (not $rack_rs->exists) {
        $c->log->debug('Could not find rack '.$c->stash('rack_name')
            .' in room '.$c->stash('datacenter_room_id_or_alias'));
        return $c->status(404);
    }

    if (not $c->is_system_admin and not $rack_rs->user_has_role($c->stash('user_id'), 'ro')) {
        $c->log->debug('User lacks the required role (ro) for rack '.$c->stash('rack_name')
            .' in room'.$c->stash('datacenter_room_id_or_alias'));
        return $c->status(403);
    }

    my $rack = $rack_rs->single;
    $c->log->debug('Found rack '.$rack->id);

    $c->status(200, $rack);
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
