package Conch::DB::ResultSet::Rack;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';
use Carp ();
use List::Util 'none';

=head1 NAME

Conch::DB::ResultSet::Rack

=head1 DESCRIPTION

Interface to queries involving racks.

=head1 METHODS

=head2 assigned_rack_units

Returns a list of rack_unit positions that are assigned to current layouts (including positions
assigned to hardware that start at an earlier position) at the specified rack. (Will return
merged results when passed a resultset referencing multiple racks, which is probably not what
you want, so don't do that.)

This is used for identifying potential conflicts when adjusting layouts.

=cut

sub assigned_rack_units ($self) {
    my @layout_data = $self->search_related('rack_layouts', undef, {
        columns => {
            rack_unit_start => 'rack_layouts.rack_unit_start',
            rack_unit_size => 'hardware_product.rack_unit_size',
        },
        join => 'hardware_product',
        order_by => 'rack_unit_start',
    })->hri->all;

    return map
        +(($_->{rack_unit_start}) .. ($_->{rack_unit_start} + ($_->{rack_unit_size} // 1) - 1)),
        @layout_data;
}

=head2 with_user_role

Constrains the resultset to those where the provided user_id has (at least) the specified role
in at least one workspace or build associated with the specified rack(s), including parent
workspaces.

=cut

sub with_user_role ($self, $user_id, $role) {
    return $self if $role eq 'none';

    my $workspace_ids_rs = $self->result_source->schema->resultset('workspace')
        ->with_user_role($user_id, $role)
        ->get_column('id');

    # since every workspace_rack entry has an equivalent entry in the parent workspace, we do
    # not need to search the workspace heirarchy here, but simply look for a role entry for any
    # workspace the rack is associated with.
    my $racks_in_ws = $self->search(
        { 'workspace_racks.workspace_id' => { -in => $workspace_ids_rs->as_query } },
        { join => 'workspace_racks' },
    );

    my $build_ids_rs = $self->result_source->schema->resultset('build')
        ->with_user_role($user_id, $role)
        ->get_column('id');

    my $racks_in_builds = $self->search({
        $self->current_source_alias.'.build_id' => { -in => $build_ids_rs->as_query },
    });

    return $racks_in_ws->union($racks_in_builds);
}

=head2 user_has_role

Checks that the provided user_id has (at least) the specified role in at least one workspace
associated with the specified rack(s) (implicitly including parent workspaces), or at least one
build associated with the rack(s).

Returns a boolean.

=cut

sub user_has_role ($self, $user_id, $role) {
    return 1 if $role eq 'none';

    Carp::croak('role must be one of: ro, rw, admin')
        if !$ENV{MOJO_MODE} and none { $role eq $_ } qw(ro rw admin);

    # since every workspace_rack entry has an equivalent entry in the parent workspace, we do
    # not need to search the workspace heirarchy here, but simply look for a role entry for any
    # workspace the rack is associated with.

    # this is Conch::DB::ResultSet::Workspace::user_has_role, unrolled
    my $ws_via_user_rs = $self
        ->related_resultset('workspace_racks')
        ->related_resultset('workspace')
        ->search_related('user_workspace_roles', { user_id => $user_id })
        ->with_role($role)
        ->related_resultset('user_account')
        ->columns('id');

    my $build_rs = $self->related_resultset('build');

    # this is Conch::DB::ResultSet::Build::user_has_role, unrolled
    my $build_via_user_rs = $build_rs
        ->search_related('user_build_roles', { user_id => $user_id })
        ->with_role($role)
        ->related_resultset('user_account')
        ->columns('id');

    my $build_via_org_rs = $build_rs
        ->related_resultset('organization_build_roles')
        ->with_role($role)
        ->related_resultset('organization')
        ->search_related('user_organization_roles', { user_id => $user_id })
        ->related_resultset('user_account')
        ->columns('id');

    return $ws_via_user_rs
        ->union_all($build_via_user_rs)
        ->union_all($build_via_org_rs)
        ->exists;
}

=head2 with_build_name

Modifies the resultset to add the C<build_name> column.

=cut

sub with_build_name ($self) {
    $self->search(undef, { join => 'build' })
        ->add_columns({ build_name => 'build.name' });
}

=head2 with_full_rack_name

Modifies the resultset to add the C<full_rack_name> column.

=cut

sub with_full_rack_name ($self) {
    my $me = $self->current_source_alias;
    $self->search(undef, { join => 'datacenter_room' })
        ->add_columns({ full_rack_name => \qq{datacenter_room.vendor_name || ':' || $me.name} });
}

=head2 with_datacenter_room_alias

Modifies the resultset to add the C<datacenter_room_alias> column.

=cut

sub with_datacenter_room_alias ($self) {
    $self->search(undef, { join => 'datacenter_room' })
        ->add_columns({ datacenter_room_alias => 'datacenter_room.alias' });
}

=head2 with_rack_role_name

Modifies the resultset to add the C<rack_role_name> column.

=cut

sub with_rack_role_name ($self) {
    $self->search(undef, { join => 'rack_role' })
        ->add_columns({ rack_role_name => 'rack_role.name' });
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
