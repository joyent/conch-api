package Conch::Route::Workspace;

use Mojo::Base -strict, -signatures;

=pod

=head1 NAME

Conch::Route::Workspace

=head1 METHODS

=head2 routes

Sets up the routes for /workspace.

Note that in all routes using C<:workspace_id_or_name>, the stash for C<workspace_id> will be
populated, as well as C<workspace_name> if the identifier was not a UUID.

=cut

sub routes {
    my $class = shift;
    my $workspace = shift;    # secured, under /workspace

    # GET /workspace
    $workspace->get('/')->to('workspace#list');

    {
        # chainable action that extracts and looks up workspace_id from the path
        # and performs basic permission checking for the workspace
        my $with_workspace = $workspace->under('/:workspace_id_or_name')
            ->to('workspace#find_workspace');

        # GET /workspace/:workspace_id_or_name
        $with_workspace->get('/')->to('workspace#get');

        # GET /workspace/:workspace_id_or_name/child
        $with_workspace->get('/child')->to('workspace#get_sub_workspaces');
        # POST /workspace/:workspace_id_or_name/child
        $with_workspace->post('/child')->to('workspace#create_sub_workspace');

        # GET /workspace/:workspace_id_or_name/device?<various query params>
        $with_workspace->get('/device')->to('workspace_device#list');

        # GET /workspace/:workspace_id_or_name/device/active -> /workspace/:workspace_id_or_name/device?active=t
        $with_workspace->get(
            '/device/active',
            sub ($c) {
                $c->redirect_to(
                    $c->url_for('/workspace/'.$c->stash('workspace_id').'/device')
                        ->query(active => 't'));
            }
        );

        # GET /workspace/:workspace_id_or_name/device/pxe
        $with_workspace->get('/device/pxe')->to('workspace_device#get_pxe_devices');

        # GET /workspace/:workspace_id_or_name/rack
        $with_workspace->get('/rack')->to('workspace_rack#list');
        # POST /workspace/:workspace_id_or_name/rack
        $with_workspace->post('/rack')->to('workspace_rack#add');

        {
            my $with_workspace_rack =
                $with_workspace->under('/rack/<rack_id:uuid>')->to('workspace_rack#find_rack');

            # GET /workspace/:workspace_id_or_name/rack/:rack_id
            $with_workspace_rack->get('/')->to('workspace_rack#get_layout');

            # DELETE /workspace/:workspace_id_or_name/rack/:rack_id
            $with_workspace_rack->delete('/')->to('workspace_rack#remove');

            # POST /workspace/:workspace_id_or_name/rack/:rack_id/layout
            $with_workspace_rack->post('/layout')->to('workspace_rack#assign_layout');
        }

        # GET /workspace/:workspace_id_or_name/room -> GONE
        $with_workspace->get('/room', sub { shift->status(410) });
        # PUT /workspace/:workspace_id_or_name/room -> GONE
        $with_workspace->put('/room', sub { shift->status(410) });

        # GET /workspace/:workspace_id_or_name/relay
        $with_workspace->get('/relay')->to('workspace_relay#list');
        # GET /workspace/:workspace_id_or_name/relay/:relay_id/device
        $with_workspace->get('/relay/:relay_id/device')->to('workspace_relay#get_relay_devices');

        # GET /workspace/:workspace_id_or_name/user
        $with_workspace->get('/user')->to('workspace_user#list');

        # POST /workspace/:workspace_id_or_name/user?send_mail=<1|0>
        $with_workspace->post('/user')->to('workspace_user#add_user');
        # DELETE /workspace/:workspace_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>
        $with_workspace->under('/user/#target_user_id_or_email')
            ->to(cb => sub ($c) { $c->find_user($c->stash('target_user_id_or_email')) })
            ->delete('/')->to('workspace_user#remove');
    }
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

=head3 C<GET /workspace>

=over 4

=item * Response: response.yaml#/WorkspacesAndRoles

=back

=head3 C<GET /workspace/:workspace_id_or_name>

=over 4

=item * Response: response.yaml#/WorkspaceAndRole

=back

=head3 C<GET /workspace/:workspace_id_or_name/child>

=over 4

=item * Response: response.yaml#/WorkspacesAndRoles

=back

=head3 C<POST /workspace/:workspace_id_or_name/child>

=over 4

=item * Requires Workspace Admin Authentication

=item * Request: input.yaml#/WorkspaceCreate

=item * Response: response.yaml#/WorkspaceAndRole

=back

=head3 C<GET /workspace/:workspace_id_or_name/device>

Accepts the following optional query parameters:

=over 4

=item * C<< graduated=<T|F> >> show only devices where the C<graduated> attribute is set/not-set

=item * C<< validated=<T|F> >> show only devices where the C<validated> attribute is set/not-set

=item * C<< health=<value> >> show only devices with the health matching the provided value (case-insensitive)

=item * C<active=t> show only devices which have reported within the last 5 minutes (this is different from all active devices)

=item * C<ids_only=t> only return device IDs, not full device details

=back

=over 4

=item * Response: response.yaml#/Devices

=back

=head3 C<< GET /workspace/:workspace_id_or_name/device/active >>

An alias for C</workspace/:workspace_id_or_name/device?active=t>.

=head3 C<GET /workspace/:workspace_id_or_name/device/pxe>

=over 4

=item * Response: response.yaml#/WorkspaceDevicePXEs

=back

=head3 C<GET /workspace/:workspace_id_or_name/rack>

=over 4

=item * Response: response.yaml#/WorkspaceRackSummary

=back

=head3 C<POST /workspace/:workspace_id_or_name/rack>

=over 4

=item * Request: input.yaml#/WorkspaceAddRack

=item * Response: Redirect to the workspace rack

=back

=head3 C<GET /workspace/:workspace_id_or_name/rack/:rack_id>

If the Accepts header specifies C<text/csv> it will return a CSV document.

=over 4

=item * Response: response.yaml#/WorkspaceAddRack

=back

=head3 C<DELETE /workspace/:workspace_id_or_name/rack/:rack_id>

=over 4

=item * Requires Workspace Admin Authentication

=item * Response: C<204 NO CONTENT>

=back

=head3 C<POST /workspace/:workspace_id_or_name/rack/:rack_id/layout>

=over 4

=item * Request: input.yaml#/WorkspaceRackLayoutUpdate

=item * Response: response.yaml#/WorkspaceRackLayoutUpdateResponse

=back

=head3 C<GET /workspace/:workspace_id_or_name/relay>

Takes one query optional parameter,  C<active_within=X> to constrain results to
those updated with in the last C<X> minutes.

=over 4

=item * Response: response.yaml#/WorkspaceRelays

=back

=head3 C<GET /workspace/:workspace_id_or_name/relay/:relay_id/device>

=over 4

=item * Response: response.yaml#/Devices

=back

=head3 C<GET /workspace/:workspace_id_or_name/user>

=over 4

=item * Response: response.yaml#/WorkspaceUsers

=back

=head3 C<< POST /workspace/:workspace_id_or_name/user?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the user

=over 4

=item * Requires Workspace Admin Authentication

=item * Request: input.yaml#/WorkspaceAddUser

=item * Response: response.yaml#/WorkspaceAndRole

=back

=head3 C<< DELETE /workspace/:workspace_id_or_name/user/#target_user_id_or_email?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to 1) to send
an email to the user

=over 4

=item * Requires Workspace Admin Authentication

=item * Returns C<204 NO CONTENT>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
