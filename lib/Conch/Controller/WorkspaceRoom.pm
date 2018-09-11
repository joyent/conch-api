package Conch::Controller::WorkspaceRoom;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use List::Compare;

=pod

=head1 NAME

Conch::Controller::WorkspaceRoom

=head1 METHODS

=head2 list

Get a list of rooms for the current workspace (as specified by :workspace_id in the path).

Response uses the Rooms json schema.

=cut

sub list ($c) {
    my @rooms = $c->stash('workspace_rs')
        ->related_resultset('workspace_datacenter_rooms')
        ->related_resultset('datacenter_room')
        ->columns([ qw(id az alias vendor_name) ])
        ->hri
        ->all;

    $c->log->debug('Found '.scalar(@rooms).' workspace rooms');
    $c->status(200, \@rooms);
}

=head2 replace_rooms

Replace the room list for the current workspace (as specified by :workspace_id in the path).
Does not permit modifying the GLOBAL workspace's rooms.

Requires 'admin' permissions on the workspace.

Response uses the Rooms json schema.

=cut

sub replace_rooms ($c) {
    return $c->status(403) unless $c->is_workspace_admin;

    my $input = $c->validate_input('WorkspaceRoomReplace');
    return if not $input;

    if ($c->stash('workspace_rs')->get_column('name')->single eq 'GLOBAL') {
        $c->log->warn("Attempt to modify GLOBAL workspace's rooms");
        return $c->status(400 => {
            error => 'Cannot modify GLOBAL workspace' # [2018-07-30 sungo] why not?
        });
    }

    # rooms in the parent workspace
    my @parent_room_ids = $c->stash('workspace_rs')
        ->related_resultset('parent_workspace')
        ->related_resultset('workspace_datacenter_rooms')
        ->get_column('datacenter_room_id')
        ->all;

    if (my @invalid_room_ids = List::Compare->new($input, \@parent_room_ids)->get_Lonly) {
        my $invalid_room_ids = join(', ', @invalid_room_ids );
        $c->log->debug("These datacenter rooms are not a member of the parent workspace: $invalid_room_ids");

        return $c->status(409 => {
            error => "Datacenter room IDs must be members of the parent workspace: $invalid_room_ids"
        });
    }

    my @current_room_ids = $c->stash('workspace_rs')
        ->related_resultset('workspace_datacenter_rooms')
        ->get_column('datacenter_room_id')
        ->all;

    my @ids_to_remove = List::Compare->new(\@current_room_ids, $input)->get_Lonly;
    my @ids_to_add = List::Compare->new(\@current_room_ids, $input)->get_Ronly;

    $c->txn_wrapper(sub ($c) {
        # remove room IDs from workspace and all children workspaces
        $c->db_workspaces
                ->and_workspaces_beneath($c->stash('workspace_id'))
                ->search_related('workspace_datacenter_rooms',
                    { datacenter_room_id => { -in => \@ids_to_remove } })
                ->delete
            if @ids_to_remove;

        # add new room IDs to workspace only, not children
        $c->db_workspace_datacenter_rooms
                ->search({ workspace_id => $c->stash('workspace_id') })
                ->populate([ map { +{ datacenter_room_id => $_ } } $input->@* ])
            if @ids_to_add;

        $c->log->debug('Replaced the rooms in workspace '.$c->stash('workspace_id'));
    });

    my @rooms = $c->stash('workspace_rs')
        ->related_resultset('workspace_datacenter_rooms')
        ->related_resultset('datacenter_room')
        ->columns([ qw(id az alias vendor_name) ])
        ->hri
        ->all;

    $c->status(200, \@rooms);
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
# vim: set ts=4 sts=4 sw=4 et :
