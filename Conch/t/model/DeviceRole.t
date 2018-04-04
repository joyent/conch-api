use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Test::Exception;

use_ok("Conch::Models");

use Conch::Pg;
use List::MoreUtils qw(qsort);

my $pgtmp = mk_tmp_db() or die;
my $pg    = Conch::Pg->new($pgtmp->uri);

my $vendor_id = $pg->db->insert(
	'hardware_vendor',
	{ name      => 'test vendor' },
	{ returning => ['id'] }
)->hash->{id};

my $hw_product_id = $pg->db->insert(
	'hardware_product',
	{
		name   => 'test hw product',
		alias  => 'alias',
		vendor => $vendor_id
	},
	{ returning => ['id'] }
)->hash->{id};


my $service;
lives_ok {
	$service = Conch::Model::DeviceService->new(name => "test")->save();
} "DeviceService->new->save";


my $r;
lives_ok {
	$r = Conch::Model::DeviceRole->new(
		hardware_product_id => $hw_product_id
	)->save;
} "->new->save";

is_deeply($r->services, [], "Services are empty");

my $r2;
lives_ok {
	$r2 = Conch::Model::DeviceRole->from_id($r->id);
} "->from_id";

is($r->id, $r2->id, "IDs match");

subtest "Add single service" => sub {
	lives_ok {
		$r->add_service($service->id);
	} "->add_service";

	is_deeply($r->services, [ $service->id ], "->services is correct");

	lives_ok {
		$r2 = Conch::Model::DeviceRole->from_id($r->id);
	} "->from_id";

	is_deeply($r2->services, [ $service->id ], "->services from db is correct");
};

subtest "Remove single service" => sub {
	lives_ok {
		$r->remove_service($service->id);
	} "->remove_service";

	is_deeply($r->services, [ ], "->services is correct");

	lives_ok {
		$r2 = Conch::Model::DeviceRole->from_id($r->id);
	} "->from_id";

	is_deeply($r2->services, [ ], "->services from db is correct");
};

my $s2;
lives_ok {
	$s2 = Conch::Model::DeviceService->new(name => "test2")->save();
} "DeviceService->new->save";


subtest "Add multiple services" => sub {
	lives_ok {
		$r->add_service($service->id);
	} "->add_service";

	lives_ok {
		$r->add_service($service->id);
	} "->add_service";

	is_deeply($r->services, [ $service->id ], "adding the same service again does nothing");

	lives_ok {
		$r2 = Conch::Model::DeviceRole->from_id($r->id);
	} "->from_id";

	is_deeply($r2->services, [ $service->id ], "->services from db is correct");



	lives_ok {
		$r->add_service($s2->id);
	} "->add_service";

	my @expected = ($service->id, $s2->id);

	qsort { $a cmp $b } @expected;

	is_deeply($r->services, \@expected, "->services is correct");

	lives_ok {
		$r2 = Conch::Model::DeviceRole->from_id($r->id);
	} "->from_id";

	is_deeply($r2->services, \@expected, "->services from db is correct");
};


subtest "Remove multiple services" => sub {

	lives_ok {
		$r->remove_service($s2->id);
	} "->remove_service";
	is_deeply($r->services, [ $service->id ], "->services is correct");

	lives_ok {
		$r2 = Conch::Model::DeviceRole->from_id($r->id);
	} "->from_id";

	is_deeply($r2->services, [ $service->id ], "->services from db is correct");

	lives_ok {
		$r->remove_service($service->id);
	} "->remove_service";
	is_deeply($r->services, [ ], "->services is correct");

	lives_ok {
		$r2 = Conch::Model::DeviceRole->from_id($r->id);
	} "->from_id";

	is_deeply($r2->services, [ ], "->services from db is correct");

};



done_testing();
