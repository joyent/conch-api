package Conch::DB::ResultSet::Rack;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';
use List::Util 'none';

=head1 NAME

Conch::DB::ResultSet::Rack

=head1 DESCRIPTION

Interface to queries involving racks.

=head1 METHODS

=head2 assigned_rack_units

Returns a list of rack_unit positions that are assigned to current layouts (including positions
assigned to hardware that start at an earlier position) at the specified rack.  (Will return
merged results when passed a resultset referencing multiple racks, so don't do that.)

This is used for identifying potential conflicts when adjusting layouts.

=cut

sub assigned_rack_units ($self) {
    my @layout_data = $self->search_related('rack_layouts', undef, {
        columns => {
            rack_unit_start => 'rack_layouts.rack_unit_start',
            rack_unit_size => 'hardware_product_profile.rack_unit',
        },
        join => { hardware_product => 'hardware_product_profile' },
        order_by => 'rack_unit_start',
    })->hri->all;

    return map
        +(($_->{rack_unit_start}) .. ($_->{rack_unit_start} + ($_->{rack_unit_size} // 1) - 1)),
        @layout_data;
}

=head2 user_has_permission

Checks that the provided user_id has (at least) the specified permission in at least one
workspace associated with the specified rack(s), including parent workspaces.

=cut

sub user_has_permission ($self, $user_id, $permission) {
    Carp::croak('permission must be one of: ro, rw, admin')
        if none { $permission eq $_ } qw(ro rw admin);

    my $rack_workspaces_ids_rs = $self
        ->related_resultset('workspace_racks')
        ->related_resultset('workspace')
        ->distinct
        ->get_column('id');

    $self->result_source->schema->resultset('workspace')
        ->and_workspaces_above($rack_workspaces_ids_rs)
        ->related_resultset('user_workspace_roles')
        ->user_has_permission($user_id, $permission);
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
