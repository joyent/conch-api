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
        { join => { device_locations => 'device' } }
    )
    ->columns({ rack_id => 'rack.id', count => { count => '*' } })
    ->distinct;  # group by all columns in final resultset

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

    my @rack_data = $racks_rs->search(undef,
        {
            columns => {
                az => 'datacenter_room.az',
                id => 'rack.id',
                name => 'rack.name',
                phase => 'rack.phase',
                rack_role_name => 'rack_role.name',
                rack_size => 'rack_role.rack_size',
            },
            join => [ qw(datacenter_room rack_role) ],
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

=head2 find_workspace_rack

Chainable action that uses the C<workspace_id> and C<rack_id> values provided in the stash
to confirm the rack is a (direct or indirect) member of the workspace.

Relies on L<Conch::Controller::Workspace/find_workspace> and
L<Conch::Controller::Rack/find_rack> to have already run, verified user roles, and populated
the stash values.

Saves C<workspace_rack_rs> to the stash.

=cut

sub find_workspace_rack ($c) {
    my $rs = $c->db_workspace_racks->search({
        workspace_id => $c->stash('workspace_id'),
        rack_id => $c->stash('rack_id'),
    });

    if (not $rs->exists) {
        $c->log->debug('Could not find rack '.$c->stash('rack_id').' in or beneath workspace '.$c->stash('workspace_id'));
        return $c->status(404);
    }

    $c->stash('workspace_rack_rs', $rs);
    return 1;
}

=head2 add

Add a rack to a workspace, unless it is the GLOBAL workspace, provided the rack
is assigned to the parent workspace of this one.

=cut

sub add ($c) {
    my $input = $c->validate_request('WorkspaceAddRack');
    return if not $input;

    return $c->status(400, { error => 'Cannot modify GLOBAL workspace' })
        if ($c->stash('workspace_name') // $c->stash('workspace_rs')->get_column('name')->single) eq 'GLOBAL';

    my $rack_id = delete $input->{id};

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

Requires the 'admin' role on the workspace.

=cut

sub remove ($c) {
    return $c->status(400, { error => 'Cannot modify GLOBAL workspace' })
        if ($c->stash('workspace_name') // $c->stash('workspace_rs')->get_column('name')->single) eq 'GLOBAL';

    my $row = $c->stash('workspace_rack_rs')->single;
    $row->delete;

    $c->log->debug('deleted workspace_rack entry for workspace_id '.$row->workspace_id.' and rack_id '.$c->stash('rack_id'));
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
