package Conch::Route::Workspace;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw(workspace_routes);

=pod

=head1 NAME

Conch::Route::Workspace

=head1 METHODS

=head2 workspace_routes

Sets up the routes for /workspace:

    GET     /workspace
    GET     /workspace/:workspace_id
    GET     /workspace/:workspace_id/child
    POST    /workspace/:workspace_id/child
    GET     /workspace/:workspace_id/device
    GET     /workspace/:workspace_id/device/active
    GET     /workspace/:workspace_id/problem
    GET     /workspace/:workspace_id/rack
    POST    /workspace/:workspace_id/rack
    GET     /workspace/:workspace_id/rack/:rack_id
    DELETE  /workspace/:workspace_id/rack/:rack_id
    GET     /workspace/:workspace_id/room
    PUT     /workspace/:workspace_id/room
    GET     /workspace/:workspace_id/user
    POST    /workspace/:workspace_id/user
    DELETE  /workspace/:workspace_id/user/#target_user

=cut

sub workspace_routes {
    my $workspace = shift;    # secured, under /workspace

    # GET /workspace
    $workspace->get('/')->to('workspace#list');

    {
        # chainable action that extracts and looks up workspace_id from the path
        # and performs basic permission checking for the workspace
        my $with_workspace = $workspace->under('/:workspace_id')
            ->to('workspace#find_workspace');

        # GET /workspace/:workspace_id
        $with_workspace->get('/')->to('workspace#get');

        # GET /workspace/:workspace_id/child
        $with_workspace->get('/child')->to('workspace#get_sub_workspaces');
        # POST /workspace/:workspace_id/child
        $with_workspace->post('/child')->to('workspace#create_sub_workspace');

        # GET /workspace/:workspace_id/device
        $with_workspace->get('/device')->to('workspace_device#list');

        # GET /workspace/:workspace_id/device/active -> /workspace/:workspace_id/device?t
        $with_workspace->get(
            '/device/active',
            sub {
                my $c = shift;
                $c->redirect_to(
                    $c->url_for('/workspace/' . $c->stash('workspace_id') . '/device')
                        ->query(active => 't'));
            }
        );

        # GET /workspace/:workspace_id/problem
        $with_workspace->get('/problem')->to('workspace_problem#list');

        # GET /workspace/:workspace_id/rack
        $with_workspace->get('/rack')->to('workspace_rack#list');
        # POST /workspace/:workspace_id/rack
        $with_workspace->post('/rack')->to('workspace_rack#add');

        {
            my $with_workspace_rack =
                $with_workspace->under('/rack/:rack_id')->to('workspace_rack#find_rack');

            # GET /workspace/:workspace_id/rack/:rack_id
            $with_workspace_rack->get('/')->to('workspace_rack#get_layout');

            # DELETE /workspace/:workspace_id/rack/:rack_id
            $with_workspace_rack->delete('/')->to('workspace_rack#remove');

            # POST /workspace/:workspace_id/rack/:rack_id/layout
            $with_workspace_rack->post('/layout')->to('workspace_rack#assign_layout');
        }

        # GET /workspace/:workspace_id/room
        $with_workspace->get('/room')->to('workspace_room#list');
        # PUT /workspace/:workspace_id/room
        $with_workspace->put('/room')->to('workspace_room#replace_rooms');

        # GET /workspace/:workspace_id/relay
        $with_workspace->get('/relay')->to('workspace_relay#list');

        # GET /workspace/:workspace_id/user
        $with_workspace->get('/user')->to('workspace_user#list');
        # POST /workspace/:workspace_id/user
        $with_workspace->post('/user')->to('workspace_user#invite');
        # DELETE /workspace/:workspace_id/user/#target_user
        $with_workspace->delete('/user/#target_user')->to('workspace_user#remove');
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
