use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);
use Test::Exception;

use_ok("Conch::Models");

use Conch::Pg;
use List::MoreUtils qw(qsort);

my $pgtmp = mk_tmp_db() or die;
my $pg    = Conch::Pg->new($pgtmp->uri);

my $d;
lives_ok {
	$d = Conch::Model::Datacenter->new(
		vendor      => 'vend0r',
		vendor_name => 'vend0r Name',
		region      => 'us-test-1',
		location    => 'the database',
	)->save();
} 'Datacenter->new->save';

my $rs;
lives_ok {
	$rs = Conch::Model::DatacenterRoom->all();
} 'empty ->all';

my $r;
lives_ok {
	$r = Conch::Model::DatacenterRoom->new(
		datacenter => $d->id,
		az => 'Az',
	)->save();
} '->new->save';

isnt($r->id, undef, "Saved has ID");

my $r2;
lives_ok {
	$r2 = Conch::Model::DatacenterRoom->from_id($r->id);
} '->from_id';

is_deeply($r2->TO_JSON, $r->TO_JSON, "fetched matches saved");

lives_ok {
	$rs = Conch::Model::DatacenterRoom->all();
} '->all';

is(scalar($rs->@*), 1, "Has the right number of elements");
is_deeply($rs->[0]->TO_JSON, $r->TO_JSON, "Fetched matches saved");


$r->vendor_name("test");
$r->save();

lives_ok {
	$r2 = Conch::Model::DatacenterRoom->from_id($r->id);
} '->from_id';

is($r2->vendor_name, "test", "value saved appropriately");


lives_ok {
	$rs = Conch::Model::DatacenterRoom->from_datacenter($d->id);
} "->from_datacenter";

is_deeply($rs, [ $r2 ], "Datacenter list is correct");

lives_ok {
	$r->burn;
} '->burn';

lives_ok {
	$r2 = Conch::Model::DatacenterRoom->from_id($r->id);
} "->from_id";

is($r2, undef, "Couldnt find deleted object");



done_testing();
