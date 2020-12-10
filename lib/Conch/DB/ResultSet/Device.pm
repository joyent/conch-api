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
in at least one build associated with the specified device(s) (also taking into
consideration the rack location of the device(s) if its phase is early enough).

This is a nested query which searches all builds in the database, so only use
this query when its impact is outweighed by the impact of filtering a large resultset of
devices in the database. (That is, usually you should start with a single device and then
apply C<< $device_rs->user_has_role($user_id, $role) >> to it.)

=cut

sub with_user_role ($self, $user_id, $role) {
    return $self if $role eq 'none';

    my $me = $self->current_source_alias;

    my $build_ids_rs = $self->result_source->schema->resultset('build')
        ->with_user_role($user_id, $role)
        ->get_column('id');

    my $devices_in_device_builds = $self->search(
        { $me.'.build_id' => { -in => $build_ids_rs->as_query } },
    );

    my $devices_in_rack_builds = $self->search(
        {
            # production devices do not consider location data to be canonical
            $me.'.phase' => { '<' => 'production' },
            'rack.build_id' => { -in => $build_ids_rs->as_query },
        },
        { join => { device_location => 'rack' } },
    );

    return $devices_in_device_builds
        ->union($devices_in_rack_builds);
}

=head2 user_has_role

Checks that the provided user_id has (at least) the specified role in at least one
build associated with the specified device(s), also taking into consideration the rack location of
the device(s) if its phase is early enough.

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
        ->related_resultset('user_account')
        ->columns('id');

    my $via_org_rs = $self
        ->related_resultset('build')
        ->related_resultset('organization_build_roles')
        ->with_role($role)
        ->related_resultset('organization')
        ->search_related('user_organization_roles', { user_id => $user_id })
        ->related_resultset('user_account')
        ->columns('id');

    return 1 if $via_user_rs->union_all($via_org_rs)->exists;

    # this checks:
    # device -> rack -> build -> user_build_role -> user
    # device -> rack -> build -> organization_build_role -> organization -> user
    $self
        # production devices do not consider location data to be canonical
        ->search({ $self->current_source_alias.'.phase' => { '<' => 'production' } })
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

Note: this is not accurate if the relay is now registered to a different user than that which
sent the report.

=cut

sub devices_reported_by_user_relay ($self, $user_id) {
    $self->search(
        { 'relay.user_id' => $user_id },
        { join => { device_relay_connections => 'relay' } },
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

Returns a hash of all (active) device settings for the specified device(s). (Will return
merged results when passed a resultset referencing multiple devices, which is probably not what
you want, so don't do that.)

=cut

sub device_settings_as_hash {
    my $self = shift;

    # when interpolated into a hash, newer rows will override older.
    return map +($_->name => $_->value),
        $self->related_resultset('device_settings')->active->order_by('created');
}

=head2 with_device_location

Modifies the resultset to add columns C<rack_id>, C<rack_name> (the full rack name including
room data) and C<rack_unit_start>.

=cut

sub with_device_location ($self) {
    $self->search(undef, { join => { device_location => { rack => 'datacenter_room' } } })
        ->add_columns({
            (map +($_ => 'device_location.'.$_), qw(rack_id rack_unit_start)),
            rack_name => \q{datacenter_room.vendor_name || ':' || rack.name},
        });
}

=head2 with_sku

Modifies the resultset to add the C<sku> column.

=cut

sub with_sku ($self) {
    $self->search(undef, { join => 'hardware_product' })
        ->add_columns({ sku => 'hardware_product.sku' });
}

=head2 with_build_name

Modifies the resultset to add the C<build_name> column.

=cut

sub with_build_name ($self) {
    $self->search(undef, { join => 'build' })
        ->add_columns({ build_name => 'build.name' });
}

=head2 location_data

Returns a resultset that provides location data (F<response.yaml#/$defs/DeviceLocation>),
optionally returned under a hash using the provided key name.

=cut

sub location_data ($self, $under_key = '') {
    $under_key .= '.' if $under_key;
    $self
        ->search(undef, {
            join => { device_location => [
                { rack_layout => 'hardware_product' },
                { rack => 'datacenter_room' },
            ] },
            columns => {
                $under_key.'az' => 'datacenter_room.az',
                $under_key.'datacenter_room' => 'datacenter_room.alias',
                $under_key.'rack' => \q{datacenter_room.vendor_name || ':' || rack.name},
                $under_key.'rack_unit_start' => 'device_location.rack_unit_start',
                map +($under_key.'target_hardware_product.'.$_ => 'hardware_product.'.$_),
                    qw(id name alias sku hardware_vendor_id),
            },
            collapse => 1,
        })
        ->hri;
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
