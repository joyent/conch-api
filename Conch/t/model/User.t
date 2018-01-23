use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Data::UUID;
my $uuid = Data::UUID->new->create_str();

use_ok("Conch::Model::User");

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new($pgtmp->uri);

my $new_user;

subtest "Create new user" => sub {
	$new_user = Conch::Model::User->create($pg, 'foo@bar.com', 'password');
	isa_ok($new_user, 'Conch::Model::User');

	is(Conch::Model::User->create($pg, 'foo@bar.com', 'password'), undef, "User conflict");
};

subtest "lookup" => sub {
	ok(Conch::Model::User->lookup($pg, $new_user->id), "lookup ID success");
	is(Conch::Model::User->lookup($pg, $uuid), undef, "lookup by ID fail");
};

subtest "lookup_by_email" => sub {
	ok(Conch::Model::User->lookup_by_email($pg, 'foo@bar.com'), "lookup by email success");
	is(Conch::Model::User->lookup_by_email($pg, 'bad@email.com'), undef, "lookup by email fail");
};

subtest "validate password" => sub {
	is($new_user->validate_password('password'), 1, "Validate good password");
	is($new_user->validate_password('bad password'), 0, "Fail to validate bad password");
};

subtest "update_password" => sub {
	my $ret = $new_user->update_password('new_password');
	is($ret, 1, "Affected 1 row");

	is(
    $new_user->validate_password('password'),
    0,
		"Auth fails appropriately with old password"
	);
	is(
    $new_user->validate_password('new_password'),
    1,
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
