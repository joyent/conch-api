
use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Test::Exception;

use_ok("Conch::Models");

use Conch::Pg;

my $pgtmp = mk_tmp_db() or die;
my $pg    = Conch::Pg->new($pgtmp->uri);
my @r;

lives_ok {
	@r = Conch::Model::DatacenterRackRole->all()->@*;
} "->all";

is_deeply(\@r, [], "No roles");

my $r;
lives_ok {
	$r = Conch::Model::DatacenterRackRole->new(
		name => 'sungo',
		rack_size => 2,
	)->save;
} "->new->save";

my $r2;
lives_ok {
	$r2 = Conch::Model::DatacenterRackRole->from_id($r->id);
} "->from_id";

is_deeply($r->TO_JSON, $r2->TO_JSON, "Get matches save");

lives_ok {
	$r2 = Conch::Model::DatacenterRackRole->from_name($r->name);
} "->from_name";

is_deeply($r->TO_JSON, $r2->TO_JSON, "Get matches save");


lives_ok {
	$r->name('sungo2');
	$r->save();
} '->save';

lives_ok {
	$r2 = Conch::Model::DatacenterRackRole->from_name('sungo2');
} "->from_name";

is_deeply($r->TO_JSON, $r2->TO_JSON, "Get matches save");


lives_ok {
	@r = Conch::Model::DatacenterRackRole->all()->@*;
} "->all";

is_deeply(\@r, [ $r2->TO_JSON ], "Role count");

lives_ok {
	$r->burn;
} '->burn';


lives_ok {
	$r2 = Conch::Model::DatacenterRackRole->from_name('sungo2');
} "->from_name";

is($r2, undef, "Cannot retrieve deleted object");

lives_ok {
	@r = Conch::Model::DatacenterRackRole->all()->@*;
} "->all";

is_deeply(\@r, [], "No roles");




done_testing();
