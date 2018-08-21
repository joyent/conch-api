use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);
use Test::Exception;

use_ok("Conch::Models");

use Conch::Pg;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg    = Conch::Pg->new($pgtmp->uri);

my $role_id = $pg->db->insert(
	'datacenter_rack_role',
	{ name => 'sungo', rack_size => 42 },
	{ returning => ['id'] }
)->hash->{id};

my $dc_id = $pg->db->insert(
	'datacenter',
	{
		vendor => 'sungo',
		region => 'space',
		location => 'mars',
	},
	{ returning => ['id'] },
)->hash->{id};

my $dc_room_id = $pg->db->insert(
	'datacenter_room',
	{ az => 'sungo', datacenter_id => $dc_id },
	{ returning => ['id'] },
)->hash->{id};

my @r;
lives_ok {
	@r = Conch::Model::DatacenterRack->all()->@*;
} "->all";

is_deeply(\@r, [], "No racks");

my $r;
lives_ok {
	$r = Conch::Model::DatacenterRack->new(
		name => 'sungo',
		datacenter_room_id => $dc_room_id,
		datacenter_rack_role_id => $role_id,
	)->save;
} "->new->save";

my $r2;
lives_ok {
	$r2 = Conch::Model::DatacenterRack->from_id($r->id);
} "->from_id";

is_deeply($r->TO_JSON, $r2->TO_JSON, "Get matches save");

lives_ok {
	$r2 = Conch::Model::DatacenterRack->from_name($r->name);
} "->from_name";

is_deeply($r->TO_JSON, $r2->TO_JSON, "Get matches save");


lives_ok {
	$r->name('sungo2');
	$r->save();
} '->save';

lives_ok {
	$r2 = Conch::Model::DatacenterRack->from_name('sungo2');
} "->from_name";

is_deeply($r->TO_JSON, $r2->TO_JSON, "Get matches save");

lives_ok {
	$r->burn;
} '->burn';


lives_ok {
	$r2 = Conch::Model::DatacenterRack->from_name('sungo2');
} "->from_name";

is($r2, undef, "Cannot retrieve deleted object");


lives_ok {
	$r = Conch::Model::DatacenterRack->new(
		name => 'sungo',
		datacenter_room_id => $dc_room_id,
		datacenter_rack_role_id => $role_id,
	)->save;
} "->new->save";


lives_ok {
	$r->update(name => 'sungo2')->save();
} '->update->save';


lives_ok {
	@r = Conch::Model::DatacenterRack->from_datacenter_room($dc_room_id)->@*;
} '->from_datacenter_room';

is(scalar(@r), 1, "Number of racks");
is($r[0]->id, $r->id, "Rack ID");


lives_ok {
	$r2 = Conch::Model::DatacenterRack->from_name('sungo2');
} "->from_name";

is_deeply($r->TO_JSON, $r2->TO_JSON, "Get matches save");






done_testing();
