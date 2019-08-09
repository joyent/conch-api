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
        # and performs basic role checking for the workspace
        my $with_workspace = $workspace->under('/:workspace_id_or_name')
            ->to('workspace#find_workspace');

        # GET /workspace/:workspace_id_or_name
        $with_workspace->get('/')->to('workspace#get');

        # GET /workspace/:workspace_id_or_name/child
        $with_workspace->get('/child')->to('workspace#get_sub_workspaces');
        # POST /workspace/:workspace_id_or_name/child?send_mail=<1|0>
        $with_workspace->post('/child')->to('workspace#create_sub_workspace');

        # GET /workspace/:workspace_id_or_name/device?<various query params>
        $with_workspace->get('/device')->to('workspace_device#list');

        # GET /workspace/:workspace_id_or_name/device/pxe
        $with_workspace->get('/device/pxe')->to('workspace_device#get_pxe_devices');

        # GET /workspace/:workspace_id_or_name/rack
        $with_workspace->get('/rack')->to('workspace_rack#list');
        # POST /workspace/:workspace_id_or_name/rack
        $with_workspace->post('/rack')->to('workspace_rack#add', require_role => 'admin');

        {
            my $with_workspace_rack =
                $with_workspace->under('/rack/<rack_id:uuid>')->to('workspace_rack#find_rack');

            # DELETE /workspace/:workspace_id_or_name/rack/:rack_id
            $with_workspace_rack->delete('/')->to('workspace_rack#remove');
        }

        # GET /workspace/:workspace_id_or_name/relay
        $with_workspace->get('/relay')->to('workspace_relay#list');
        # GET /workspace/:workspace_id_or_name/relay/<relay_id:uuid>/device
        $with_workspace->get('/relay/<relay_id:uuid>/device')->to('workspace_relay#get_relay_devices');

        # like $with_workspace, but requires 'admin' access to the workspace
        my $with_workspace_admin = $workspace->under('/:workspace_id_or_name')
            ->to('workspace#find_workspace', require_role => 'admin');

        # GET /workspace/:workspace_id_or_name/user
        $with_workspace_admin->get('/user')->to('workspace_user#list');

        # POST /workspace/:workspace_id_or_name/user?send_mail=<1|0>
        $with_workspace_admin->post('/user')->to('workspace_user#add_user');
        # DELETE /workspace/:workspace_id_or_name/user/#target_user_id_or_email?send_mail=<1|0>
        $with_workspace_admin->under('/user/#target_user_id_or_email')->to('user#find_user')
            ->delete('/')->to('workspace_user#remove');
    }
}

1;
__END__

=pod

Unless otherwise noted, all routes require authentication.

Users will require access to the workspace (or one of its ancestors) at a minimum
L<role|Conch::DB::Result::UserWorkspaceRole/role>, as indicated.

=head3 C<GET /workspace>

=over 4

=item * User requires the read-only role

=item * Response: response.yaml#/WorkspacesAndRoles

=back

=head3 C<GET /workspace/:workspace_id_or_name>

=over 4

=item * User requires the read-only role

=item * Response: response.yaml#/WorkspaceAndRole

=back

=head3 C<GET /workspace/:workspace_id_or_name/child>

=over 4

=item * User requires the read-only role

=item * Response: response.yaml#/WorkspacesAndRoles

=back

=head3 C<< POST /workspace/:workspace_id_or_name/child?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to C<1>) to send
an email to the parent workspace admins.

=over 4

=item * User requires the read/write role

=item * Request: request.yaml#/WorkspaceCreate

=item * Response: response.yaml#/WorkspaceAndRole

=back

=head3 C<GET /workspace/:workspace_id_or_name/device>

Accepts the following optional query parameters:

=over 4

=item * C<< validated=<1|0> >> show only devices where the C<validated> attribute is set/not-set

=item * C<< health=<value> >> show only devices with the health matching the provided value

=item * C<active_minutes=X> show only devices which have reported within the last X minutes (this is different from all active devices)

=item * C<ids_only=1> only return device IDs, not full device details

=back

=over 4

=item * User requires the read-only role

=item * Response: response.yaml#/Devices

=back

=head3 C<GET /workspace/:workspace_id_or_name/device/pxe>

=over 4

=item * User requires the read-only role

=item * Response: response.yaml#/WorkspaceDevicePXEs

=back

=head3 C<GET /workspace/:workspace_id_or_name/rack>

=over 4

=item * User requires the read-only role

=item * Response: response.yaml#/WorkspaceRackSummary

=back

=head3 C<POST /workspace/:workspace_id_or_name/rack>

=over 4

=item * User requires the admin role

=item * Request: request.yaml#/WorkspaceAddRack

=item * Response: Redirect to the workspace's racks

=back

=head3 C<DELETE /workspace/:workspace_id_or_name/rack/:rack_id>

=over 4

=item * User requires the admin role

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /workspace/:workspace_id_or_name/relay>

Takes one query optional parameter, C<?active_minutes=X> to constrain results to
those updated with in the last C<X> minutes.

=over 4

=item * User requires the read-only role

=item * Response: response.yaml#/WorkspaceRelays

=back

=head3 C<GET /workspace/:workspace_id_or_name/relay/:relay_id/device>

=over 4

=item * User requires the read-only role

=item * Response: response.yaml#/Devices

=back

=head3 C<GET /workspace/:workspace_id_or_name/user>

=over 4

=item * User requires the admin role

=item * Response: response.yaml#/WorkspaceUsers

=back

=head3 C<< POST /workspace/:workspace_id_or_name/user?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to C<1>) to send
an email to the user and workspace admins.

=over 4

=item * User requires the admin role

=item * Request: request.yaml#/WorkspaceAddUser

=item * Response: C<204 NO CONTENT>

=back

=head3 C<< DELETE /workspace/:workspace_id_or_name/user/:target_user_id_or_email?send_mail=<1|0> >>

Takes one optional query parameter C<< send_mail=<1|0> >> (defaults to C<1>) to send
an email to the user and workspace admins.

=over 4

=item * User requires the admin role

=item * Returns C<204 NO CONTENT>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
