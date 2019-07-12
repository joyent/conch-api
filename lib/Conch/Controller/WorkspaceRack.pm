package Conch::Controller::WorkspaceRack;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use List::Util 'reduce';

=pod

=head1 NAME

Conch::Controller::WorkspaceRack

=head1 METHODS

=head2 list

Get a list of racks for the indicated workspace.

Response uses the WorkspaceRackSummary json schema.

=cut

sub list ($c) {
    my $racks_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack');

    my $device_health_rs = $racks_rs->search(
        { 'device.id' => { '!=' => undef } },
        {
            columns => { rack_id => 'rack.id' },
            select => [{ count => '*', -as => 'count' }],
            join => { device_locations => 'device' },
            distinct => 1,  # group by all columns in final resultset
        },
    );

    my $invalid_rs = $device_health_rs->search(
        { 'device.validated' => undef },
        { '+columns' => { status => 'device.health' } },
    );

    my $valid_rs = $device_health_rs->search(
        { 'device.validated' => { '!=' => undef } },
    );

    # turn valid, invalid health data into a hash keyed by rack id:
    my %device_progress;
    foreach my $entry ($invalid_rs->hri->all, $valid_rs->hri->all) {
        $device_progress{$entry->{rack_id}}{$entry->{status} // 'valid'} += $entry->{count};
    }

    my @rack_data = $racks_rs->as_subselect_rs->search(undef,
        {
            columns => {
                az => 'datacenter_room.az',
                id => 'rack.id',
                name => 'rack.name',
                phase => 'rack.phase',
                role_name => 'rack_role.name',
                rack_size => 'rack_role.rack_size',
            },
            join => [ qw(datacenter_room rack_role) ],
            collapse => 1,
        },
    )->hri->all;

    my $final_rack_data = reduce {
        push $a->{delete $b->{az}}->@*, +{
            $b->%*,
            device_progress => $device_progress{$b->{id}} // {},
        };
        $a;
    } +{}, @rack_data;

    $c->status(200, $final_rack_data);
}

=head2 find_rack

Chainable action that takes the C<rack_id> provided in the path and looks it up in the
database, stashing a resultset to access it as C<rack_rs>.

=cut

sub find_rack ($c) {
    my $rack_id = $c->stash('rack_id');
    my $rack_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->search_related('rack', { 'rack.id' => $rack_id });

    if (not $rack_rs->exists) {
        $c->log->debug('Could not find rack '.$rack_id);
        return $c->status(404);
    }

    # store the simplified query to access the device, now that we've confirmed the user has
    # permission to access it.
    # No queries have been made yet, so you can add on more criteria or prefetches.
    $c->stash('rack_rs',
        $c->db_racks->search_rs({ 'rack.id' => $rack_id }));

    $c->log->debug('Found rack '.$rack_id);
    return 1;
}

=head2 add

Add a rack to a workspace, unless it is the GLOBAL workspace, provided the rack
is assigned to the parent workspace of this one.

=cut

sub add ($c) {
    return $c->status(403) if not $c->is_workspace_admin;

    my $input = $c->validate_request('WorkspaceAddRack');
    return if not $input;

    my $rack_id = delete $input->{id};

    return $c->status(400, { error => 'Cannot modify GLOBAL workspace' })
        if $c->stash('workspace_rs')->get_column('name')->single eq 'GLOBAL';

    # note this only checks one layer up, rather than all the way up the hierarchy.
    if (not $c->stash('workspace_rs')
            ->related_resultset('parent_workspace')
            ->search_related('workspace_racks', { rack_id => $rack_id })
            ->exists) {
        return $c->status(409,
            { error => "Rack '$rack_id' must be assigned in parent workspace to be assignable." },
        );
    }

    $c->db_workspace_racks->update_or_create({
        workspace_id => $c->stash('workspace_id'),
        rack_id => $rack_id,
    });

    # update rack with additional info, if provided.
    if (keys $input->%*) {
        my $rack = $c->db_racks->find($rack_id);
        $rack->set_columns($input);
        $rack->update({ updated => \'now()' }) if $rack->is_changed;
    }

    $c->status(303, '/workspace/'.$c->stash('workspace_id').'/rack');
}

=head2 remove

Remove a rack from a workspace (and all descendants).

Requires 'admin' permissions on the workspace.

=cut

sub remove ($c) {
    return $c->status(400, { error => 'Cannot modify GLOBAL workspace' })
        if $c->stash('workspace_rs')->get_column('name')->single eq 'GLOBAL';

    $c->db_workspaces
        ->and_workspaces_beneath($c->stash('workspace_id'))
        ->search_related('workspace_racks', { rack_id => $c->stash('rack_id') })
        ->delete;

    return $c->status(204);
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
