package Conch::DB::ResultSet::Device;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use Carp ();
use List::Util 'none';

=head1 NAME

Conch::DB::ResultSet::Device

=head1 DESCRIPTION

Interface to queries involving devices.

=head1 METHODS

=head2 user_has_permission

Checks that the provided user_id has (at least) the specified permission in at least one
workspace associated with the specified device(s).

=cut

sub user_has_permission {
    my ($self, $user_id, $permission) = @_;

    Carp::croak('permission must be one of: ro, rw, admin')
        if none { $permission eq $_ } qw(ro rw admin);

    $self->related_resultset('device_location')
        ->related_resultset('rack')
        ->associated_workspaces
        ->related_resultset('user_workspace_roles')
        ->user_has_permission($user_id, $permission);
}

=head2 devices_without_location

Restrict results to those that do not have a registered location.

=cut

sub devices_without_location {
    my $self = shift;

    $self->search({
        # all devices in device_location table
        $self->current_source_alias . '.id' => {
            -not_in => $self->result_source->schema->resultset('DeviceLocation')->get_column('device_id')->as_query
         },
    });
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
