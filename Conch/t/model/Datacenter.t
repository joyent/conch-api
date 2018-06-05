use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Test::Exception;

use_ok("Conch::Models");

use Conch::Pg;
use List::MoreUtils qw(qsort);

my $pgtmp = mk_tmp_db() or die;
my $pg    = Conch::Pg->new($pgtmp->uri);

my $d;
lives_ok {
	$d = Conch::Model::Datacenter->all();
} 'empty ->all';


lives_ok {
	$d = Conch::Model::Datacenter->new(
		vendor      => 'vend0r',
		vendor_name => 'vend0r Name',
		region      => 'us-test-1',
		location    => 'the database',
	)->save();
} '->new->save';

isnt($d->id, undef, "Has an ID");

my $d2;
lives_ok {
	$d2 = Conch::Model::Datacenter->from_id($d->id);
} "->from_id";

is_deeply($d2->TO_JSON, $d->TO_JSON, "Fetched matches saved");

my $dc;
lives_ok {
	$dc = Conch::Model::Datacenter->all();
} '->all';

is(scalar($dc->@*), 1, "Has the right number of elements");
is_deeply($dc->[0]->TO_JSON, $d->TO_JSON, "Fetched matches saved");

$d->vendor("New vendor");
$d->save();

lives_ok {
	$d2 = Conch::Model::Datacenter->from_id($d->id);
} "->from_id";
is($d2->vendor, "New vendor", "value saved appropriately");

lives_ok {
	$d->burn;
} '->burn';

lives_ok {
	$d2 = Conch::Model::Datacenter->from_id($d->id);
} "->from_id";

is($d2, undef, "Couldnt find deleted object");



done_testing();
