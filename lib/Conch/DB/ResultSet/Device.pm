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
in at least one workspace or build associated with the specified device(s), including parent
workspaces.

This is a nested query which searches all workspaces and builds in the database, so only use
this query when its impact is outweighed by the impact of filtering a large resultset of
devices in the database.  (That is, usually you should start with a single device and then
apply C<< $device_rs->user_has_role($user_id, $role) >> to it.)

=cut

sub with_user_role ($self, $user_id, $role) {
    return $self if $role eq 'none';

    my $workspace_ids_rs = $self->result_source->schema->resultset('workspace')
        ->with_user_role($user_id, $role)
        ->get_column('id');

    # since every workspace_rack entry has an equivalent entry in the parent workspace, we do
    # not need to search the workspace heirarchy here, but simply look for a role entry for any
    # workspace the rack is associated with.

    my $devices_in_ws = $self->search(
        { 'workspace_racks.workspace_id' => { -in => $workspace_ids_rs->as_query } },
        { join => { device_location => { rack => 'workspace_racks' } } },
    );

    my $build_ids_rs = $self->result_source->schema->resultset('build')
        ->with_user_role($user_id, $role)
        ->get_column('id');

    my $devices_in_builds = $self->search(
        { -or => [
                { 'rack.build_id' => { -in => $build_ids_rs->as_query } },
                { $self->current_source_alias.'.build_id' => { -in => $build_ids_rs->as_query } },
            ],
        },
        { join => { device_location => 'rack' } },
    );

    return $devices_in_ws->union($devices_in_builds);
}

=head2 user_has_role

Checks that the provided user_id has (at least) the specified role in at least one
workspace or build associated with the specified device(s) (including parent workspaces).

Returns a boolean.

=cut

sub user_has_role ($self, $user_id, $role) {
    return 1 if $role eq 'none';

    # this checks:
    # device -> build -> user_build_role -> user
    # device -> build -> organization_build_role -> organization -> user
    my $via_user_rs = $self
        ->related_resultset('build')
        ->search_related('user_build_roles', { user_id => $user_id })
        ->with_role($role)
        ->related_resultset('user_account');

    my $via_org_rs = $self
        ->related_resultset('build')
        ->related_resultset('organization_build_roles')
        ->with_role($role)
        ->related_resultset('organization')
        ->search_related('user_organization_roles', { user_id => $user_id })
        ->related_resultset('user_account');

    my $has_rack_role = $via_user_rs->union_all($via_org_rs)->exists;
    return $has_rack_role if $has_rack_role;

    # this checks:
    # device -> rack -> workspace -> user_workspace_role -> user
    # device -> rack -> workspace -> organization_workspace_role -> organization -> user
    # device -> rack -> build -> user_build_role -> user
    # device -> rack -> build -> organization_build_role -> organization -> user
    $self
        ->related_resultset('device_location')
        ->related_resultset('rack')
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

=head2 device_settings_as_hash

Returns a hash of all (active) device settings for the specified device(s).  (Will return
merged results when passed a resultset referencing multiple devices, which is probably not what
you want, so don't do that.)

=cut

sub device_settings_as_hash {
    my $self = shift;

    # when interpolated into a hash, newer rows will override older.
    return map +($_->name => $_->value),
        $self->related_resultset('device_settings')->active->order_by('created');
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
