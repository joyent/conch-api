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
    $workspace->get('/')->to('workspace#get_all');

    {
        # chainable actions that extract and look up workspace_id from the path
        # and performs basic role checking for the workspace
        my $with_workspace = $workspace->under('/:workspace_id_or_name')
            ->to('workspace#find_workspace');
        my $with_workspace_admin = $workspace->under('/:workspace_id_or_name')
            ->to('workspace#find_workspace', require_role => 'admin');

        # GET /workspace/:workspace_id_or_name
        $with_workspace->get('/')->to('workspace#get');

        # GET /workspace/:workspace_id_or_name/child
        $with_workspace->get('/child')->to('workspace#get_sub_workspaces');
        # POST /workspace/:workspace_id_or_name/child?send_mail=<1|0>
        $with_workspace->post('/child')->to('workspace#create_sub_workspace');

        # GET /workspace/:workspace_id_or_name/device?<various query params>
        $with_workspace->get('/device')->to('workspace_device#get_all');

        # GET /workspace/:workspace_id_or_name/device/pxe
        $with_workspace->get('/device/pxe')->to('workspace_device#get_pxe_devices');

        # GET /workspace/:workspace_id_or_name/rack
        $with_workspace->get('/rack')->to('workspace_rack#get_all');
        # POST /workspace/:workspace_id_or_name/rack
        $with_workspace_admin->post('/rack')->to('workspace_rack#add');

        {
            my $with_workspace_rack =
                $with_workspace->under('/rack/:rack_id_or_name')->to('rack#find_rack')
                    ->under('/')->to('workspace_rack#find_workspace_rack');

            # DELETE /workspace/:workspace_id_or_name/rack/:rack_id
            $with_workspace_rack->delete('/')->to('workspace_rack#remove');
        }

        # GET /workspace/:workspace_id_or_name/relay
        $with_workspace->get('/relay')->to('workspace_relay#get_all');
        # GET /workspace/:workspace_id_or_name/relay/<relay_id:uuid>/device
        $with_workspace->get('/relay/<relay_id:uuid>/device')->to('workspace_relay#get_relay_devices');

        # GET /workspace/:workspace_id_or_name/user
        $with_workspace_admin->get('/user')->to('workspace_user#get_all');

        # POST /workspace/:workspace_id_or_name/user?send_mail=<1|0>
        $with_workspace_admin->find_user_from_payload->post('/user')->to('workspace_user#add_user');
        # DELETE /workspace/:workspace_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>
        $with_workspace_admin->under('/user/#target_user_id_or_email')->to('user#find_user')
            ->delete('/')->to('workspace_user#remove');
    }
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

Users will require access to the workspace (or one of its ancestors) at a minimum
L<role|Conch::DB::Result::UserWorkspaceRole/role>, as indicated.

=head2 C<GET /workspace>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/WorkspacesAndRoles>

=back

=head2 C<GET /workspace/:workspace_id_or_name>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/WorkspaceAndRole>

=back

=head2 C<GET /workspace/:workspace_id_or_name/child>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/WorkspacesAndRoles>

=back

=head2 C<< POST /workspace/:workspace_id_or_name/child?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to C<1>) to send
an email to the parent workspace admins.

=over 4

=item * User requires the read/write role

=item * Request: F<request.yaml#/definitions/WorkspaceCreate>

=item * Response: F<response.yaml#/definitions/WorkspaceAndRole>

=back

=head2 C<GET /workspace/:workspace_id_or_name/device>

Accepts the following optional query parameters:

=over 4

=item * C<< validated=<1|0> >> show only devices where the C<validated> attribute is set/not-set

=item * C<health=:value> show only devices with the health matching the provided value

=item * C<active_minutes=:X> show only devices which have reported within the last X minutes (this is different from all active devices)

=item * C<ids_only=1> only return device IDs, not full device details

=back

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/Devices>, F<response.yaml#/definitions/DeviceIds> or F<response.yaml#/definitions/DeviceSerials>

=back

=head2 C<GET /workspace/:workspace_id_or_name/device/pxe>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/WorkspaceDevicePXEs>

=back

=head2 C<GET /workspace/:workspace_id_or_name/rack>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/WorkspaceRackSummary>

=back

=head2 C<POST /workspace/:workspace_id_or_name/rack>

=over 4

=item * User requires the admin role

=item * Request: F<request.yaml#/definitions/WorkspaceAddRack>

=item * Response: Redirect to the workspace's racks

=back

=head2 C<DELETE /workspace/:workspace_id_or_name/rack/:rack_id_or_name>

=over 4

=item * User requires the admin role

=item * Response: C<204 NO CONTENT>

=back

=head2 C<GET /workspace/:workspace_id_or_name/relay>

Takes one query optional parameter, C<?active_minutes=X> to constrain results to
those updated with in the last C<X> minutes.

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/WorkspaceRelays>

=back

=head2 C<GET /workspace/:workspace_id_or_name/relay/:relay_id/device>

=over 4

=item * User requires the read-only role

=item * Response: F<response.yaml#/definitions/Devices>

=back

=head2 C<GET /workspace/:workspace_id_or_name/user>

=over 4

=item * User requires the admin role

=item * Response: F<response.yaml#/definitions/WorkspaceUsers>

=back

=head2 C<< POST /workspace/:workspace_id_or_name/user?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to C<1>) to send
an email to the user and workspace admins.

=over 4

=item * User requires the admin role

=item * Request: F<request.yaml#/definitions/WorkspaceAddUser>

=item * Response: C<204 NO CONTENT>

=back

=head2 C<< DELETE /workspace/:workspace_id_or_name/user/:target_user_id_or_email?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to C<1>) to send
an email to the user and workspace admins.

=over 4

=item * User requires the admin role

=item * Response: C<204 NO CONTENT>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
