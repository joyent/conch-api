use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Test::Exception;

use_ok("Conch::Models");

use Conch::Pg;

my $pgtmp = mk_tmp_db() or die;
my $pg    = Conch::Pg->new($pgtmp->uri);

my $role = Conch::Model::DatacenterRackRole->new(
	name      => 'sungo',
	rack_size => 42,
)->save();

my $dc = Conch::Model::Datacenter->new(
	vendor   => 'sungo',
	region   => 'space',
	location => 'mars',
)->save();

my $room = Conch::Model::DatacenterRoom->new(
	az         => 'sungo',
	datacenter => $dc->id,
)->save();

my $rack = Conch::Model::DatacenterRack->new(
	name               => 'sungo',
	datacenter_room_id => $room->id,
	role               => $role->id,
)->save();

my $hardware_vendor_id = $pg->db->insert(
	'hardware_vendor',
	{ name      => 'test vendor' },
	{ returning => ['id'] }
)->hash->{id};
my $hardware_product_id = $pg->db->insert(
	'hardware_product',
	{
		name   => 'test hw product',
		alias  => 'alias',
		vendor => $hardware_vendor_id
	},
	{ returning => ['id'] }
)->hash->{id};


###############

my @r;
lives_ok {
	@r = Conch::Model::DatacenterRackLayout->all()->@*;
} "->all";

is_deeply(\@r, [], "No rack layouts");

my $r;
lives_ok {
	$r = Conch::Model::DatacenterRackLayout->new(
		rack_id    => $rack->id,
		product_id => $hardware_product_id,
		ru_start   => 1,
	)->save;
} "DatacenterRackLayout->new->save";

my $r2;
lives_ok {
	$r2 = Conch::Model::DatacenterRackLayout->from_id($r->id);
} "->from_id";

is_deeply($r->TO_JSON, $r2->TO_JSON, "Get matches save");

lives_ok {
	$r->ru_start(2);
	$r->save();
} '->save';

lives_ok {
	$r2 = Conch::Model::DatacenterRackLayout->from_id($r->id);
} "->from_id";

is($r2->ru_start, 2, "RU Start value");

lives_ok {
	$r->update(ru_start => 3)->save();
} '->update->save';

lives_ok {
	$r2 = Conch::Model::DatacenterRackLayout->from_id($r->id);
} "->from_id";

is($r2->ru_start, 3, "RU Start value");

lives_ok {
	@r = Conch::Model::DatacenterRackLayout->all()->@*;
} "->all";

is(scalar(@r), 1, "Rack layout count");

lives_ok {
	@r = Conch::Model::DatacenterRackLayout->from_rack_id($rack->id)->@*;
} '->from_rack_id';
is(scalar(@r), 1, "Rack layout count");



lives_ok {
	$r->burn;
} '->burn';

lives_ok {
	$r2 = Conch::Model::DatacenterRackLayout->from_id($r->id);
} "->from_name";

is($r2, undef, "Cannot retrieve deleted object");

lives_ok {
	@r = Conch::Model::DatacenterRackLayout->all()->@*;
} "->all";

is_deeply(\@r, [], "No rack layouts");




done_testing();
