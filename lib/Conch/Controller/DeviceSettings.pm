package Conch::Controller::DeviceSettings;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use List::Util 'pairmap';

=pod

=head1 NAME

Conch::Controller::DeviceSettings

=head1 METHODS

=head2 set_all

Overrides all settings for a device with the given payload.
Existing settings are deactivated even if they are not being replaced with new ones.

=cut

sub set_all ($c) {
    my $input = $c->stash('request_data');

    # we cannot do device_rs->related_resultset, or ->create loses device_id
    my $settings_rs = $c->db_device_settings->search({ device_id => $c->stash('device_id') });

    # overwriting existing non-tag keys requires 'admin'; otherwise only require 'rw'.
    my @non_tags = grep !/^tag\./, keys $input->%*;
    my $requires_role =
        @non_tags && $settings_rs->active->search({ name => \@non_tags })->exists ? 'admin' : 'rw';

    # 'rw' already checked by find_device
    if ($requires_role eq 'admin'
            and not $c->is_system_admin
            and not $c->stash('device_rs')->devices_reported_by_user_relay($c->stash('user_id'))->exists
            and not $c->stash('device_rs')->user_has_role($c->stash('user_id'), $requires_role)) {
        $c->log->debug('User lacks the required role ('.$requires_role.') for device '.$c->stash('device_id'));
        return $c->status(403);
    }

    $c->schema->txn_do(sub {
        # deactivate existing settings with the same keys
        $settings_rs->search({ name => { -in => [ keys $input->%* ] } })
            ->active
            ->deactivate;

        # store new settings
        $settings_rs->populate([ pairmap { +{ name => $a, value => $b } } $input->%* ]);
    });

    $c->status(204);
}

=head2 set_single

Sets a single setting on a device. If the setting already exists, it is
overwritten, unless the value is unchanged.

=cut

sub set_single ($c) {
    my $input = $c->stash('request_data');
    my $setting_key = $c->stash('key');
    return $c->status(400, { error => "Setting key in request payload must match name in the URL ('$setting_key')" })
        if not exists $input->{$setting_key};

    my $setting_value = $input->{$setting_key};

    # we cannot do device_rs->related_resultset, or ->create loses device_id
    my $settings_rs = $c->db_device_settings->search({ device_id => $c->stash('device_id') });

    my $existing_value = $settings_rs->active->search({ name => $setting_key })->get_column('value')->single;

    # return early if the setting exists and is not being altered
    return $c->status(204) if $existing_value and $existing_value eq $setting_value;

    # overwriting existing non-tag keys requires 'admin'; otherwise only require 'rw'.
    my $requires_role = $existing_value && $setting_key !~ /^tag\./ ? 'admin' : 'rw';

    # 'rw' already checked by find_device
    if ($requires_role eq 'admin'
            and not $c->is_system_admin
            and not $c->stash('device_rs')->devices_reported_by_user_relay($c->stash('user_id'))->exists
            and not $c->stash('device_rs')->user_has_role($c->stash('user_id'), $requires_role)) {
        $c->log->debug('User lacks the required role ('.$requires_role.') for device '.$c->stash('device_id'));
        return $c->status(403);
    }

    $c->schema->txn_do(sub {
        $settings_rs->search({ name => $setting_key })->active->deactivate;
        $settings_rs->create({ name => $setting_key, value => $setting_value });
    });

    $c->status(204);
}

=head2 get_all

Get all settings for a device as a hash

Response uses the DeviceSettings json schema.

=cut

sub get_all ($c) {
    $c->status(200, +{ $c->stash('device_rs')->device_settings_as_hash });
}

=head2 get_single

Get a single setting from a device

Response uses the DeviceSetting json schema.

=cut

sub get_single ($c) {
    my $setting_key = $c->stash('key');

    # no need to check for the 'ro' role - find_device() already performed that check

    my $setting = $c->stash('device_rs')
        ->search_related('device_settings', { name => $setting_key })
        ->active
        ->order_by({ -desc => 'created' })
        ->rows(1)
        ->single;

    if (not $setting) {
        $c->log->debug('Could not find device setting '.$setting_key.' for device '.$c->stash('device_id'));
        return $c->status(404);
    }
    $c->status(200, { $setting_key => $setting->value });
}

=head2 delete_single

Delete a single setting from a device, provide that setting was previously set

=cut

sub delete_single ($c) {
    my $setting_key = $c->stash('key');
    my $requires_role = $setting_key !~ /^tag\./ ? 'admin' : 'rw';

    # 'rw' already checked by find_device
    if ($requires_role eq 'admin'
            and not $c->is_system_admin
            and not $c->stash('device_rs')->devices_reported_by_user_relay($c->stash('user_id'))->exists
            and not $c->stash('device_rs')->user_has_role($c->stash('user_id'), $requires_role)) {
        $c->log->debug('User lacks the required role ('.$requires_role.') for device '.$c->stash('device_id'));
        return $c->status(403);
    }

    # 0 rows updated -> 0E0 which is boolean truth, not false
    if ($c->stash('device_rs')
            ->search_related('device_settings', { name => $setting_key })
            ->active
            ->deactivate <= 0) {
        $c->log->debug('Could not find device setting '.$setting_key.' for device '.$c->stash('device_id'));
        return $c->status(404);
    }

    return $c->status(204);
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
