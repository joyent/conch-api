use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Mojo::Conch::Model::User;
use Data::Printer;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new($pgtmp->uri);

new_ok('Mojo::Conch::Model::User');

my $user_model = Mojo::Conch::Model::User->new(
    hash_password => sub { reverse shift },
    pg => $pg,
    validate_against_hash => sub { reverse(shift) eq shift }
  );
my $new_user;

subtest "Create new user" => sub {
  can_ok($user_model, 'create');
  my $attempt = $user_model->create('foo@bar.com', 'password');
  isa_ok($attempt, 'Attempt::Success');
  isa_ok($attempt->value, 'Mojo::Conch::Class::User');
  $new_user = $attempt->value;

  my $another_new_user = $user_model->create('foo@bar.com', 'password');
  isa_ok($another_new_user, 'Attempt::Fail');
  isa_ok($another_new_user->failure, 'Mojo::Conch::Error::Conflict');
};

subtest "lookup" => sub {
  can_ok($user_model, 'lookup');
  ok($user_model->lookup($new_user->id),
    "lookup ID success");

  my $bad_id = $new_user->id;
  $bad_id =~ s/[0-9]/0/g;
  ok(! $user_model->lookup($bad_id),
    "lookup by email fail");

};

subtest "lookup_by_email" => sub {
  can_ok($user_model, 'lookup_by_email');
  ok($user_model->lookup_by_email('foo@bar.com'),
    "lookup by email success");

  ok(! $user_model->lookup_by_email('bad@email.com'),
    "lookup by email fail");
};

subtest "authenticate" => sub {
  can_ok($user_model, 'authenticate');
  isa_ok($user_model->authenticate($new_user->email, 'password'),
    "Attempt::Success", "authentication success");

  isa_ok($user_model->authenticate($new_user->email, 'bad_password'),
    "Attempt::Fail", "bad password fails authentication");

  isa_ok($user_model->authenticate('bad@email.com', 'password'),
    "Attempt::Fail", "bad email fails authentication");
};

subtest "update_password" => sub {
  can_ok($user_model, 'update_password');
  my $a = $user_model->update_password($new_user->id, 'new_password');
  ok(!$user_model->authenticate($new_user->email, 'password'),
    "old password fails authentication");
  ok($user_model->authenticate($new_user->email, 'new_password'),
    "new password authenticates");
};


done_testing();
