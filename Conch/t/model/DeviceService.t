use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Test::Exception;

use_ok("Conch::Models");

use Conch::Pg;

my $pgtmp = mk_tmp_db() or die;
my $pg    = Conch::Pg->new($pgtmp->uri);

my $s;
lives_ok {
	$s = Conch::Model::DeviceService->new(name => "test")->save();
} "->new->save";

my $s2;
lives_ok {
	$s2 = Conch::Model::DeviceService->from_name("test");
} "->from_name";

is($s->id, $s2->id, "IDs match");

lives_ok {
	$s2 = Conch::Model::DeviceService->from_id($s->id);
} "->from_id";

is($s->id, $s2->id, "IDs match");

done_testing();
