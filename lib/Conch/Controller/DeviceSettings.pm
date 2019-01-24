package Conch::Controller::DeviceSettings;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

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
	my $body = $c->req->json;
	return $c->status( 400, { error => 'Payload required' } )
		unless $body;

	# we cannot do device_rs->related_resultset, or ->create loses device_id
	my $settings_rs = $c->db_device_settings->search({ device_id => $c->stash('device_id') });

	# overwriting existing non-tag keys requires 'admin'; otherwise only require 'rw'.
	my @non_tags = grep { !/^tag\./ } keys %$body;
	my $perm_needed =
		@non_tags && $settings_rs->active->search({ name => \@non_tags })->exists ? 'admin' : 'rw';

	if (not $c->stash('device_rs')->user_has_permission($c->stash('user_id'), $perm_needed)) {
		$c->log->debug("failed permission check (required $perm_needed)");
		return $c->status(403, { error => 'insufficient permissions' });
	}

	# deactivate existing settings with the same keys
	$settings_rs->search({ name => { -in => [ keys %$body ] } })
		->active
		->deactivate;

	# store new settings
	$settings_rs->populate([ pairmap { +{ name => $a, value => $b } } $body->%* ]);

	$c->status(200);
}

=head2 set_single

Sets a single setting on a device. If the setting already exists, it is
overwritten, unless the value is unchanged.

=cut

sub set_single ($c) {
	my $body          = $c->req->json;
	my $setting_key   = $c->stash('key');
	my $setting_value = $body->{$setting_key};

	return $c->status(400, { error => "Setting key in request object must match name in the URL ('$setting_key')" })
		unless $setting_value;

	# we cannot do device_rs->related_resultset, or ->create loses device_id
	my $settings_rs = $c->db_device_settings->search({ device_id => $c->stash('device_id') });

	my $existing_setting = $settings_rs->active->search({ name => $setting_key })->single;

	# return early if the setting exists and is not being altered
	return $c->status(204) if $existing_setting and $existing_setting->value eq $setting_value;

	# overwriting existing non-tag keys requires 'admin'; otherwise only require 'rw'.
	my $perm_needed = $existing_setting && $setting_key !~ /^tag\./ ? 'admin' : 'rw';
	if (not $c->stash('device_rs')->user_has_permission($c->stash('user_id'), $perm_needed)) {
		$c->log->debug("failed permission check (required $perm_needed)");
		return $c->status(403, { error => 'insufficient permissions' });
	}

	$existing_setting->update({ deactivated => \'NOW()' }) if $existing_setting;

	$settings_rs->create({ name => $setting_key, value => $setting_value });

	$c->status(200);
}

=head2 get_all

Get all settings for a device as a hash

=cut

sub get_all ($c) {
    my %settings = $c->stash('device_rs')->single->device_settings_as_hash;
    $c->status(200, \%settings);
}

=head2 get_single

Get a single setting from a device

=cut

sub get_single ($c) {
	my $setting_key = $c->stash('key');

	# no need to check 'ro' perms - find_device() already checked the workspace

	my $setting = $c->stash('device_rs')
		->related_resultset('device_settings')
		->active
		->search(
			{ name => $setting_key },
			{ order_by => { -desc => 'created' }, rows => 1 },
		)->single;

	return $c->status( 404, { error => "No such setting '$setting_key'" } )
		unless $setting;

	$c->status(200, { $setting_key => $setting->value });
}

=head2 delete_single

Delete a single setting from a device, provide that setting was previously set

=cut

sub delete_single ($c) {
	my $setting_key = $c->stash('key');

	my $perm_needed = $setting_key !~ /^tag\./ ? 'admin' : 'rw';

	if (not $c->stash('device_rs')->user_has_permission($c->stash('user_id'), $perm_needed)) {
		$c->log->debug("failed permission check (required $perm_needed)");
		return $c->status(403, { error => 'insufficient permissions' });
	}

	unless (
		# 0 rows updated -> 0E0 which is boolean truth, not false
		$c->stash('device_rs')
			->related_resultset('device_settings')
			->active
			->search({ name => $setting_key })
			->deactivate > 0
	) {
		return $c->status( 404, { error => "No such setting '$setting_key'" } );
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
one at http://mozilla.org/MPL/2.0/.

=cut
