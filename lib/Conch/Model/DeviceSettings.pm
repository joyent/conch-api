=pod

=head1 NAME

Conch::Model::DeviceSettings

=head1 METHODS

=cut
package Conch::Model::DeviceSettings;
use Mojo::Base -base, -signatures;

use Try::Tiny;

use Conch::Pg;

=head2 set_settings

Associate a collection of settings (in a hashref) with a device.

Device settings values, unlike user settings, are strings rather than JSON
values.

=cut
sub set_settings ( $self, $device_id, $settings ) {
	my $db = Conch::Pg->new->db;
	try {
		my $tx = $db->begin;
		for my $setting_key ( keys %{$settings} ) {
			my $value = $settings->{$setting_key};
			_deactivate_device_setting( $device_id, $setting_key );
			_insert_device_setting( $device_id, $setting_key, $value );
		}
		$tx->commit;
	}
	catch {
		Mojo::Exception->throw(__PACKAGE__."->set_settings: $_");
		return undef
	};
	return 1;
}

sub _insert_device_setting ( $device_id, $setting_key, $value ) {
	Conch::Pg->new->db->insert(
		'device_settings',
		{
			device_id => $device_id,
			name      => $setting_key,
			value     => $value
		}
	);
}

sub _deactivate_device_setting ( $device_id, $setting_key ) {
	Conch::Pg->new->db->update(
		'device_settings',
		{ deactivated => 'now()' },
		{ device_id   => $device_id, name => $setting_key, deactivated => undef }
	);
}

=head2 get_settings

Retrieve all settings associated with a device and build a hash

=cut
sub get_settings ( $self, $device_id ) {
	my $settings = Conch::Pg->new->db->select( 'device_settings', undef,
		{ deactivated => undef, device_id => $device_id } )->expand->hashes;
	return $settings->reduce(
		sub {
			$a->{ $b->{name} } = $b->{value};
			$a;
		},
		{}
	);
}

=head2 delete_device_setting

Delete (deactivate) a specifie device setting.

=cut
sub delete_device_setting ( $self, $device_id, $setting_key ) {
	_deactivate_device_setting( $device_id, $setting_key )->rows;
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

