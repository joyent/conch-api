use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use_ok("Conch::Model::User");
use_ok("Conch::Model::UserSettings");

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new($pgtmp->uri);

new_ok('Conch::Model::UserSettings');

my $user_settings_model = Conch::Model::UserSettings->new(
    pg => $pg,
  );

my $user_model = Conch::Model::User->new(
    pg => $pg,
  );
my $new_user = $user_model->create('foo@bar.com', 'password');

fail("Test 'set_settings'");

my $settings = {foo => 'bar', deeply => { nested => 'hash' }};

subtest 'set user settings' => sub {
  my $set_attempt = $user_settings_model->set_settings($new_user->id, $settings);
  ok($set_attempt->is_success, 'set user settings successful');
};

subtest 'get user settings' => sub {
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
  delete $settings->{foo};
  my $deleted = $user_settings_model->delete_user_setting($new_user->id, 'foo');
  ok($deleted, 'Deleted stored setting');

  my $user_settings = $user_settings_model->get_settings($new_user->id);
  is_deeply($user_settings, $settings, 'stored settings match');
};

done_testing();
