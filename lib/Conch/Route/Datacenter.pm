package Conch::Route::Datacenter;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Datacenter

=head1 METHODS

=head2 routes

Sets up the routes for /dc, /room, /rack_role, /rack and /layout:

    GET     /dc
    POST    /dc
    GET     /dc/:datacenter_id
    POST    /dc/:datacenter_id
    DELETE  /dc/:datacenter_id
    GET     /dc/:datacenter_id/rooms

    GET     /room
    POST    /room
    GET     /room/:datacenter_room_id
    POST    /room/:datacenter_room_id
    DELETE  /room/:datacenter_room_id
    GET     /room/:datacenter_room_id/racks

    GET     /rack_role
    POST    /rack_role
    GET     /rack_role/:rack_role_id_or_name
    POST    /rack_role/:rack_role_id_or_name
    DELETE  /rack_role/:rack_role_id_or_name

    GET     /rack
    POST    /rack
    GET     /rack/:rack_id
    POST    /rack/:rack_id
    DELETE  /rack/:rack_id
    GET     /rack/:rack_id/layouts
    GET     /rack/:rack_id/assignment
    POST    /rack/:rack_id/assignment
    DELETE  /rack/:rack_id/assignment

    GET     /layout
    POST    /layout
    GET     /layout/:layout_id
    POST    /layout/:layout_id
    DELETE  /layout/:layout_id

=cut

sub routes {
    my $class = shift;
    my $r = shift;      # secured, under /

    # /dc
    {
        my $dc = $r->any('/dc');
        $dc->to({ controller => 'datacenter' });

        # GET /dc
        $dc->get('/')->to('#get_all');
        # POST /dc
        $dc->post('/')->to('#create');

        my $with_datacenter = $dc->under('/:datacenter_id')->to('#find_datacenter');

        # GET /dc/:datacenter_id
        $with_datacenter->get('/')->to('#get_one');
        # POST /dc/:datacenter_id
        $with_datacenter->post('/')->to('#update');
        # DELETE /dc/:datacenter_id
        $with_datacenter->delete('/')->to('#delete');
        # GET /dc/:datacenter_id/rooms
        $with_datacenter->get('/rooms')->to('#get_rooms');
    }

    # /room
    {
        my $room = $r->any('/room');
        $room->to({ controller => 'datacenter_room' });

        # GET /room
        $room->get('/')->to('#get_all');
        # POST /room
        $room->post('/')->to('#create');

        my $with_datacenter_room = $room->under('/:datacenter_room_id')
            ->to('#find_datacenter_room');

        # GET /room/:datacenter_room_id
        $with_datacenter_room->get('/')->to('#get_one');
        # POST /room/:datacenter_room_id
        $with_datacenter_room->post('/')->to('#update');
        # DELETE /room/:datacenter_room_id
        $with_datacenter_room->delete('/')->to('#delete');
        # GET /room/:datacenter_room_id/racks
        $with_datacenter_room->get('/racks')->to('#racks');
    }

    # /rack_role
    {
        my $rack_role = $r->any('/rack_role');
        $rack_role->to({ controller => 'rack_role' });

        # GET /rack_role
        $rack_role->get('/')->to('#get_all');
        # POST /rack_role
        $rack_role->post('/')->to('#create');

        my $with_rack_role = $rack_role->under('/:rack_role_id_or_name')->to('#find_rack_role');

        # GET /rack_role/:rack_role_id_or_name
        $with_rack_role->get('/')->to('#get');
        # POST /rack_role/:rack_role_id_or_name
        $with_rack_role->post('/')->to('#update');
        # DELETE /rack_role/:rack_role_id_or_name
        $with_rack_role->delete('/')->to('#delete');
    }

    # /rack
    {
        my $rack = $r->any('/rack');
        $rack->to({ controller => 'rack' });

        # GET /rack
        $rack->get('/')->to('#get_all');
        # POST /rack
        $rack->post('/')->to('#create');

        my $with_rack = $rack->under('/:rack_id')->to('#find_rack');

        # GET /rack/:rack_id
        $with_rack->get('/')->to('#get');
        # POST /rack/:rack_id
        $with_rack->post('/')->to('#update');
        # DELETE /rack/:rack_id
        $with_rack->delete('/')->to('#delete');
        # GET /rack/:rack_id/layouts
        $with_rack->get('/layouts')->to('#layouts');

        # GET /rack/:rack_id/assignment
        $with_rack->get('/assignment')->to('#get_assignment');
        # POST /rack/:rack_id/assignment
        $with_rack->post('/assignment')->to('#set_assignment');
        # DELETE /rack/:rack_id/assignment
        $with_rack->delete('/assignment')->to('#delete_assignment');
    }

    # /layout
    {
        my $layout = $r->any('/layout');
        $layout->to({ controller => 'rack_layout' });

        # GET /layout
        $layout->get('/')->to('#get_all');
        # POST /layout
        $layout->post('/')->to('#create');

        my $with_layout = $layout->under('/:layout_id')->to('#find_rack_layout');

        # GET /layout/:layout_id
        $with_layout->get('/')->to('#get');
        # POST /layout/:layout_id
        $with_layout->post('/')->to('#update');
        # DELETE /layout/:layout_id
        $with_layout->delete('/')->to('#delete');
    }
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
