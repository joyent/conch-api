package Mojo::Conch::Model::DeviceSettings;
use Mojo::Base -base, -signatures;

use Attempt qw(fail success try);
use DDP;

has 'pg';

# Device settings values, unlike user settings, are text fields rather than JSON
sub set_settings ($self, $device_id, $settings) {
  my $db = $self->pg->db;
  my $attempt = try {
    my $tx = $db->begin;
    for my $setting_key ( keys %{$settings} ) {
      my $value = $settings->{$setting_key};
      _deactivate_device_setting( $db, $device_id, $setting_key );
      _insert_device_setting( $db, $device_id, $setting_key, $value );
    }
    $tx->commit;
  };
  return $attempt;
}

sub _insert_device_setting ( $db, $device_id, $setting_key, $value ) {
  $db->insert('device_settings',
    { device_id => $device_id, name => $setting_key, value => $value
    });
}

sub _deactivate_device_setting ( $db, $device_id, $setting_key ) {
  $db->update('device_settings',
    { deactivated => 'now()' },
    { device_id => $device_id, name => $setting_key, deactivated => undef }
  );
}

sub get_settings ($self, $device_id) {
  my $settings = $self->pg->db->select('device_settings', undef,
    { deactivated => undef, device_id => $device_id }
  )->expand->hashes;
  return $settings->reduce(sub {
    $a->{ $b->{name} } = $b->{value};
    $a;
  }, {});
}

sub delete_device_setting ($self, $device_id, $setting_key) {
  _deactivate_device_setting($self->pg->db, $device_id, $setting_key)->rows;
}

1;
