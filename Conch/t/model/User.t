use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Data::UUID;
my $uuid = Data::UUID->new->create_str();

use_ok("Conch::Model::User");

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new($pgtmp->uri);

new_ok('Conch::Model::User');

my $model = new_ok("Conch::Model::User", [
	pg =>  $pg,
]);


my $new_user;

subtest "Create new user" => sub {
	$new_user = $model->create('foo@bar.com', 'password');
	isa_ok($new_user, 'Conch::Model::User');

	is($model->create('foo@bar.com', 'password'), undef, "User conflict");
};

subtest "lookup" => sub {
	ok($model->lookup($new_user->id), "lookup ID success");
	is($model->lookup($uuid), undef, "lookup by ID fail");
};

subtest "lookup_by_email" => sub {
	ok($model->lookup_by_email('foo@bar.com'), "lookup by email success");
	is($model->lookup_by_email('bad@email.com'), undef, "lookup by email fail");
};

subtest "validate password" => sub {
	is($new_user->validate_password('password'), 1, "Validate good password");
	is($new_user->validate_password('bad password'), 0, "Fail to validate bad password");
};

subtest "authenticate" => sub {
	ok(
		$model->authenticate($new_user->email, 'password'),
		"Auth passes with good email and good pass"
	);

	ok(
		!$model->authenticate($new_user->email, 'bad_password'),
		"Auth fails with good email and bad pass"
	);

	ok(
		!$model->authenticate('bad@email.com', 'password'),
		"Auth fails with bad email"
	);

	ok(
		$model->authenticate($new_user->name, 'password'),
		"Auth passes with good name and good pass"
	);

	ok(
		!$model->authenticate($new_user->name, 'bad_password'),
		"Auth fails with good name and bad pass"
	);

};

subtest "update_password" => sub {
	my $ret = $new_user->update_password('new_password');
	is($ret, 1, "Affected 1 row");
	ok(
		!$model->authenticate($new_user->email,'password'),
		"Auth fails appropriately with old password"
	);
	ok(
		$model->authenticate($new_user->email, 'new_password'),
		"Auth passes with new password"
	);

	my $u = Conch::Model::User->new(
		pg    => $pg,
		id    => $uuid,
		email => 'wat@wat',
		name  => 'wat',
	);
	is(
		$u->update_password("test"), 
		0, 
		"Updating password on non-existent user does nothing"
	);

};


done_testing();
