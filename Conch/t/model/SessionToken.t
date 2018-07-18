use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::ConchTmpDB qw(mk_tmp_db);

use Conch::Pg;

use_ok("Conch::Model::SessionToken");

use Conch::Model::User;
use Conch::Model::SessionToken;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg = Conch::Pg->new( $pgtmp->uri );

my $user = Conch::Model::User->create( 'foo@bar.com', 'password' );

my $token;
subtest "Create new token" => sub {
	lives_ok {
		$token =
			Conch::Model::SessionToken->create( $user->id, time + 10 )
	};
	ok( $token, 'Token created' );
};

subtest "Check token" => sub {
	my $check = Conch::Model::SessionToken->check_token( $user->id, $token );
	ok( $check, 'Token valid' );

	my $bad_check = Conch::Model::SessionToken->check_token( $user->id, $token."a" );
	ok( !$bad_check, 'Token was not valid' );
};


subtest "Use token" => sub {
	my $used = Conch::Model::SessionToken->use_token( $user->id, $token );
	ok( $used, 'Token used' );

	my $re_used = Conch::Model::SessionToken->use_token( $user->id, $token );
	ok( !$re_used, 'Token not present and cannot be reused' );
};

subtest "Using expired token" => sub {
	my $expired_token = Conch::Model::SessionToken->create( $user->id, time - 1 );
	my $expired =
		Conch::Model::SessionToken->check_token( $user->id, $expired_token );
	ok( !$expired, 'Token expired and not present' );
};

subtest "Revoking user tokens" => sub {
	my $new_token = Conch::Model::SessionToken->create( $user->id, time + 10 );
	my $revoked_count =
		Conch::Model::SessionToken->revoke_user_tokens( $user->id );
	ok( $revoked_count, 'Non-zero count of revoked tokens' );

	my $revoked_used =
		Conch::Model::SessionToken->check_token( $user->id, $new_token );
	ok( !$revoked_used, 'Revoked token cannot be used and not present' );
};

done_testing();
