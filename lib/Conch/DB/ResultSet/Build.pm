package Conch::DB::ResultSet::Build;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';
use Carp ();
use List::Util 'none';

=head1 NAME

Conch::DB::ResultSet::Build

=head1 DESCRIPTION

Interface to queries involving builds.

=head1 METHODS

=head2 admins

All the 'admin' users for the provided build(s). Pass a true argument to also include all
system admin users in the result.

=cut

sub admins ($self, $include_sysadmins = undef) {
    my $direct_users_rs = $self->search_related('user_build_roles', { role => 'admin' })
        ->related_resultset('user_account');

    my $organization_users_rs = $self->search_related('organization_build_roles',
            { 'organization_build_roles.role' => 'admin' })
        ->related_resultset('organization')
        ->related_resultset('user_organization_roles')
        ->related_resultset('user_account');

    my $rs = $direct_users_rs->union_all($organization_users_rs);

    $rs = $rs->union_all($self->result_source->schema->resultset('user_account')->search_rs({ is_admin => 1 }))
        if $include_sysadmins;

    return $rs
        ->active
        ->distinct
        ->order_by('user_account.name');
}

=head2 with_user_role

Constrains the resultset to those builds where the provided user_id has (at least) the
specified role.

=cut

sub with_user_role ($self, $user_id, $role) {
    return $self if $role eq 'none';

    Carp::croak('role must be one of: ro, rw, admin')
        if !$ENV{MOJO_MODE} and none { $role eq $_ } qw(ro rw admin);

    my $via_user_rs = $self->search(
        {
            $role ne 'ro' ? ('user_build_roles.role' => { '>=' => $role } ) : (),
            'user_build_roles.user_id' => $user_id,
        },
        { join => 'user_build_roles' },
    );

    my $via_org_rs = $self->search(
        {
            $role ne 'ro' ? ('organization_build_roles.role' => { '>=' => $role }) : (),
            'user_organization_roles.user_id' => $user_id,
        },
        { join => { organization_build_roles => { organization => 'user_organization_roles' } } } );

    return $via_user_rs->union_all($via_org_rs)->distinct;
}

=head2 user_has_role

Checks that the provided user_id has (at least) the specified role in at least one build in the
resultset.

Returns a boolean.

=cut

sub user_has_role ($self, $user_id, $role) {
    return 1 if $role eq 'none';

    Carp::croak('role must be one of: ro, rw, admin')
        if !$ENV{MOJO_MODE} and none { $role eq $_ } qw(ro rw admin);

    my $via_user_rs = $self
        ->search_related('user_build_roles', { user_id => $user_id })
        ->with_role($role)
        ->related_resultset('user_account')
        ->columns('id');

    my $via_org_rs = $self
        ->related_resultset('organization_build_roles')
        ->with_role($role)
        ->related_resultset('organization')
        ->search_related('user_organization_roles', { user_id => $user_id })
        ->related_resultset('user_account')
        ->columns('id');

    return $via_user_rs->union_all($via_org_rs)->exists;
}

=head2 with_device_health_counts

Modifies the resultset to add on a column named C<device_health> containing an array of arrays
of correlated counts of device.health values for each build.

=cut

sub with_device_health_counts ($self) {
    my $health_rs = $self->correlate('devices')
        ->search(undef, { select => [ \'array[health::text, count(*)::text]' ] })
        ->group_by('health');

    $self->add_columns({ device_health => { array => $health_rs->as_query } });
}

=head2 with_device_phase_counts

Modifies the resultset to add on a column named C<device_phases> containing an array of arrays
of correlated counts of device.phase values for each build.

=cut

sub with_device_phase_counts ($self) {
    my $phases_rs = $self->correlate('devices')
        ->search(undef, { select => [ \'array[phase::text, count(*)::text]' ] })
        ->group_by('phase');

    $self->add_columns({ device_phases => { array => $phases_rs->as_query } });
}

=head2 with_rack_phase_counts

Modifies the resultset to add on a column named C<rack_phases> containing an array of arrays
of correlated counts of rack.phase values for each build.

=cut

sub with_rack_phase_counts ($self) {
    my $phases_rs = $self->correlate('racks')
        ->search(undef, { select => [ \'array[phase::text, count(*)::text]' ] })
        ->group_by('phase');

    $self->add_columns({ rack_phases => { array => $phases_rs->as_query } });
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
# vim: set sts=2 sw=2 et :
