package Conch::Model::UserSettings;
use Mojo::Base -base, -signatures;

use Attempt qw(fail success try);
use Mojo::JSON 'to_json';
use DDP;

has 'pg';

sub set_settings ($self, $user_id, $settings) {
  my $db = $self->pg->db;
  my $attempt = try {
    my $tx = $db->begin;
    for my $setting_key ( keys %{$settings} ) {
      my $value = $settings->{$setting_key};
      _deactivate_user_setting( $db, $user_id, $setting_key );
      _insert_user_setting( $db, $user_id, $setting_key, $value );
    }
    $tx->commit;
  };
  return $attempt;
}

sub _insert_user_setting ( $db, $user_id, $setting_key, $value ) {
  $db->insert('user_settings',
    { user_id => $user_id, name => $setting_key, value => to_json($value)
    });
}

sub _deactivate_user_setting ( $db, $user_id, $setting_key ) {
  $db->update('user_settings',
    { deactivated => 'now()' },
    { user_id => $user_id, name => $setting_key, deactivated => undef }
  );
}

sub get_settings ($self, $user_id) {
  my $settings = $self->pg->db->select('user_settings', undef,
    { deactivated => undef, user_id => $user_id }
  )->expand->hashes;
  return $settings->reduce(sub {
    $a->{ $b->{name} } = $b->{value};
    $a;
  }, {});
}

sub delete_user_setting ($self, $user_id, $setting_key) {
  _deactivate_user_setting($self->pg->db, $user_id, $setting_key)->rows;
}

1;
