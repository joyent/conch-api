use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Mojo::Conch::Model::User;
use Mojo::Conch::Model::UserSettings;
use Data::Printer;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new($pgtmp->uri);

new_ok('Mojo::Conch::Model::UserSettings');

my $user_settings_model = Mojo::Conch::Model::UserSettings->new(
    pg => $pg,
  );

my $user_model = Mojo::Conch::Model::User->new(
    hash_password => sub { reverse shift },
    pg => $pg,
    validate_against_hash => sub { reverse(shift) eq shift }
  );
my $new_user = $user_model->create('foo@bar.com', 'password')->value;

can_ok($user_settings_model, 'set_settings');

my $settings = {foo => 'bar', deeply => { nested => 'hash' }};

subtest 'set user settings' => sub {
  my $set_attempt = $user_settings_model->set_settings($new_user->id, $settings);
  ok($set_attempt->is_success, 'set user settings successful');
};

subtest 'get user settings' => sub {
  can_ok($user_settings_model, 'get_settings');
  my $user_settings = $user_settings_model->get_settings($new_user->id);
  is_deeply($user_settings, $settings, 'stored settings match stored');
};

subtest 'update user setting' => sub {
  $settings->{foo} = 'baz';
  my $next_attempt = $user_settings_model->set_settings($new_user->id, $settings);
  ok($next_attempt->is_success, 'set user settings successful');

  my $user_settings = $user_settings_model->get_settings($new_user->id);
  is_deeply($user_settings, $settings, 'stored settings match');
};

subtest 'delete user setting' => sub {
  can_ok($user_settings_model, 'delete_user_setting');
  delete $settings->{foo};
  my $deleted = $user_settings_model->delete_user_setting($new_user->id, 'foo');
  ok($deleted, 'Deleted stored setting');

  my $user_settings = $user_settings_model->get_settings($new_user->id);
  is_deeply($user_settings, $settings, 'stored settings match');
};

done_testing();
