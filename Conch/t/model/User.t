use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use DDP;

use Data::UUID;
my $uuid = Data::UUID->new->create_str();

use_ok("Conch::Model::User");

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $new_user;

subtest "Create new user" => sub {
	$new_user = Conch::Model::User->create( $pg, 'foo@bar.com', 'password' );
	isa_ok( $new_user, 'Conch::Model::User' );

	is( Conch::Model::User->create( $pg, 'foo@bar.com', 'password' ),
		undef, "User conflict" );
};

subtest "lookup" => sub {
	ok( Conch::Model::User->lookup( $pg, $new_user->id ), "lookup ID success" );
	is( Conch::Model::User->lookup( $pg, $uuid ), undef, "lookup by ID fail" );
};

subtest "lookup_by_email" => sub {
	ok( Conch::Model::User->lookup_by_email( $pg, 'foo@bar.com' ),
		"lookup by email success" );
	is( Conch::Model::User->lookup_by_email( $pg, 'bad@email.com' ),
		undef, "lookup by email fail" );
};

subtest "validate password" => sub {
	ok( $new_user->validate_password('password'), "Validate good password" );
	ok( ! $new_user->validate_password('bad password'),
		 "Fail to validate bad password" );
};

subtest "update_password" => sub {
	my $ret = $new_user->update_password('new_password');
	is( $ret, 1, "Affected 1 row" );

	ok( ! $new_user->validate_password('password'),
		"Auth fails appropriately with old password" );
	ok( $new_user->validate_password('new_password'),
		"Auth passes with new password" );

	my $u = Conch::Model::User->new(
		pg    => $pg,
		id    => $uuid,
		email => 'wat@wat',
		name  => 'wat',
	);
	is( $u->update_password("test"),
		0, "Updating password on non-existent user does nothing" );
};

subtest "Settings" => sub {
	is_deeply( $new_user->settings(), {}, "Empty user has no settings" );

	is( $new_user->set_setting( test => "string" ),
		1, "Set a setting affects 1 row" );

	is_deeply( $new_user->settings, { test => "string" },
		"Have one setting now" );

	is_deeply( $new_user->setting("test"),
		"string", "setting 'test' is 'string'" );
	is_deeply( $new_user->set_setting( "test" => "string2" ),
		1, "Updating setting affects 1 row" );
	is_deeply( $new_user->setting("test"),
		"string2", "setting 'test' is 'string2'" );

	is( $new_user->delete_setting("test"), 1, "Delete a setting affects 1 row" );
	is_deeply( $new_user->setting("test"), undef, "setting 'test' is now undef" );

	is_deeply( $new_user->settings(), {}, "No settings now" );

	my %settings = ( test2 => "wat" );
	is_deeply(
		$new_user->set_settings( \%settings ),
		\%settings, "New settings match",
	);

	%settings = ( test3 => "wat" );
	is_deeply(
		$new_user->set_settings( \%settings ),
		\%settings, "New new settings match",
	);

};

done_testing();
