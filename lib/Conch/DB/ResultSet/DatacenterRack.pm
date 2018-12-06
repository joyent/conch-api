package Conch::DB::ResultSet::DatacenterRack;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

=head1 NAME

Conch::DB::ResultSet::DatacenterRack

=head1 DESCRIPTION

Interface to queries involving racks.

=head1 METHODS

=head2 associated_workspaces

Chainable resultset (in the Conch::DB::ResultSet::Workspace namespace) that finds all
workspaces that are associated with the specified rack(s) (either directly, or via a
datacenter_room).

To go in the other direction, see L<Conch::DB::ResultSet::Workspace/associated_racks>.

=cut

sub associated_workspaces {
    my $self = shift;

    my $rack_workspace_ids = $self->related_resultset('workspace_datacenter_racks')
        ->get_column('workspace_id');

    my $rack_room_workspace_ids = $self->related_resultset('datacenter_room')
        ->related_resultset('workspace_datacenter_rooms')
        ->get_column('workspace_id');

    $self->result_source->schema->resultset('workspace')->search(
        {
            'workspace.id' => [
                { -in => $rack_workspace_ids->as_query },
                { -in => $rack_room_workspace_ids->as_query },
            ],
        },
        { alias => 'workspace' },
    );
}

=head2 assigned_rack_units

Returns a list of rack_unit positions that are assigned to current layouts (including positions
assigned to hardware that start at an earlier position) at the specified rack.  (Will return
merged results when passed a resultset referencing multiple racks, so don't do that.)

This is used for identifying potential conflicts when adjusting layouts.

=cut

sub assigned_rack_units {
    my $self = shift;

    my @layout_data = $self->search_related('datacenter_rack_layouts', undef, {
        columns => {
            rack_unit_start => 'datacenter_rack_layouts.rack_unit_start',
            rack_unit_size => 'hardware_product_profile.rack_unit',
        },
        join => { 'hardware_product' => 'hardware_product_profile' },
        order_by => 'rack_unit_start',
    })->hri->all;

    return map {
        ($_->{rack_unit_start}) .. ($_->{rack_unit_start} + $_->{rack_unit_size} - 1)
    } @layout_data;
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
