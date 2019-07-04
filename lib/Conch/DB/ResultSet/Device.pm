package Conch::DB::ResultSet::Device;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::Device

=head1 DESCRIPTION

Interface to queries involving devices.

=head1 METHODS

=head2 with_user_role

Constrains the resultset to those where the provided user_id has (at least) the specified role
in at least one workspace associated with the specified device(s), including parent workspaces.

=cut

sub with_user_role ($self, $user_id, $role) {
    my $schema = $self->result_source->schema;
    my $workspace_ids_rs = $schema->resultset('user_workspace_role')
        ->search({ user_id => $user_id })
        ->with_role($role)
        ->get_column('workspace_id');

    my $all_workspace_ids_rs = $schema->resultset('workspace')
        ->and_workspaces_beneath($workspace_ids_rs)
        ->get_column('id');

    $self->search(
        { 'workspace_racks.workspace_id' => { -in => $all_workspace_ids_rs->as_query } },
        { join => { device_location => { rack_layout => { rack => 'workspace_racks' } } } },
    );
}

=head2 user_has_role

Checks that the provided user_id has (at least) the specified role in at least one
workspace associated with the specified device(s), including parent workspaces.

=cut

sub user_has_role ($self, $user_id, $role) {
    my $device_workspaces_ids_rs = $self
        ->related_resultset('device_location')
        ->related_resultset('rack')
        ->related_resultset('workspace_racks')
        ->related_resultset('workspace')
        ->distinct
        ->get_column('id');

    $self->result_source->schema->resultset('workspace')
        ->and_workspaces_above($device_workspaces_ids_rs)
        ->related_resultset('user_workspace_roles')
        ->user_has_role($user_id, $role);
}

=head2 devices_without_location

Restrict results to those that do not have a registered location.

=cut

sub devices_without_location ($self) {
    $self->search(
        { 'device_location.rack_id' => undef },
        { join => 'device_location' },
    );
}

=head2 devices_reported_by_user_relay

Restrict results to those that have sent a device report proxied by a relay
registered using the provided user's credentials.

=cut

sub devices_reported_by_user_relay ($self, $user_id) {
    $self->search(
        { 'user_relay_connections.user_id' => $user_id },
        { join => { device_relay_connections => { relay => 'user_relay_connections' } } },
    );
}

=head2 latest_device_report

Returns a resultset that finds the most recent device report matching the device(s). This is
not a window function, so only one report is returned for all matching devices, not one report
per device! (We probably never need to do the latter. *)

* but if we did, you'd want something like:

    $self->search(undef, {
        '+columns' => {
            $col => $self->correlate('device_reports')
                ->columns($col)
                ->order_by({ -desc => 'device_reports.created' })
                ->rows(1)
                ->as_query
        },
    });

=cut

sub latest_device_report ($self) {
    $self->related_resultset('device_reports')
        ->order_by({ -desc => 'device_reports.created' })
        ->rows(1);
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
# vim: set ts=4 sts=4 sw=4 et :
