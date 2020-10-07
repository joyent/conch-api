package Conch::Controller::DatacenterRoom;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';
use List::Util 'any';

=pod

=head1 NAME

Conch::Controller::DatacenterRoom

=head1 METHODS

=head2 find_datacenter_room

Chainable action that uses the C<datacenter_room_id_or_alias> value provided in the stash
(usually via the request URL) to look up a datacenter_room, and stashes the query to get to it
in C<datacenter_room_rs>.

If C<require_role> is provided in the stash, it is used as the minimum required role for the user to
continue; otherwise the user must be a system admin.

=cut

sub find_datacenter_room ($c) {
    my $identifier = $c->stash('datacenter_room_id_or_alias');

    my $rs = $c->db_datacenter_rooms->search({
        'datacenter_room.'.(is_uuid($identifier) ? 'id' : 'alias') => $identifier,
    });

    $c->log->debug('Looking up datacenter room '.$identifier);

    if (not $rs->exists) {
        $c->log->debug('Could not find datacenter room '.$identifier);
        return $c->status(404);
    }

    if (not $c->is_system_admin
            and not $rs->related_resultset('racks')->user_has_role($c->stash('user_id'), $c->stash('require_role'))) {
        $c->log->debug('User lacks the required role ('.$c->stash('require_role').') for datacenter room '.$identifier);
        return $c->status(403);
    }

    $c->log->debug('Found datacenter room');
    $c->stash('datacenter_room_rs', $rs);
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
    my $room = $c->stash('datacenter_room_rs')->single;
    $c->res->headers->location('/room/'.$room->id);
    $c->status(200, $room);
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

    return $c->status(409, { error => 'a room already exists with that vendor_name' })
        if $c->db_datacenter_rooms->search({ vendor_name => $input->{vendor_name} })->exists;

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

    my $room = $c->stash('datacenter_room_rs')->single;

    return $c->status(409, { error => 'a room already exists with that alias' })
        if $input->{alias} and $input->{alias} ne $room->alias
            and $c->db_datacenter_rooms->search({ alias => $input->{alias} })->exists;

    return $c->status(409, { error => 'a room already exists with that vendor_name' })
        if $input->{vendor_name} and $input->{vendor_name} ne $room->vendor_name
            and $c->db_datacenter_rooms->search({ vendor_name => $input->{vendor_name} })->exists;

    $c->res->headers->location('/room/'.$room->id);

    $room->set_columns($input);
    return $c->status(204) if not $room->is_changed;

    $room->update({ updated => \'now()' });
    $c->log->debug('Updated datacenter room '.$c->stash('datacenter_room_id_or_alias'));
    $c->status(303);
}

=head2 delete

Permanently delete a datacenter room.

=cut

sub delete ($c) {
    if ($c->stash('datacenter_room_rs')->related_resultset('racks')->exists) {
        $c->log->debug('Cannot delete datacenter room: in use by one or more racks');
        return $c->status(409, { error => 'cannot delete a datacenter_room when a rack is referencing it' });
    }

    $c->stash('datacenter_room_rs')->delete;
    $c->log->debug('Deleted datacenter room '.$c->stash('datacenter_room_id_or_alias'));
    return $c->status(204);
}

=head2 racks

Response uses the Racks json schema.

=cut

sub racks ($c) {
    my $rs = $c->stash('datacenter_room_rs')->related_resultset('racks');

    # filter the results by what the user is permitted to see. Depending on the size of the
    # initial resultset, this could be slow!
    $rs = $rs->with_user_role($c->stash('user_id'), 'ro') if not $c->is_system_admin;

    my @racks = $rs
        ->as_subselect_rs
        ->with_build_name
        ->with_full_rack_name
        ->with_rack_role_name
        ->with_datacenter_room_alias
        ->order_by('racks.name')
        ->all;

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
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut

1;
# vim: set ts=4 sts=4 sw=4 et :
