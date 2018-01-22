use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Data::UUID;
use IO::All;

use Data::Printer;

BEGIN {
	use_ok("Test::ConchTmpDB");
	use_ok("Conch::Route", qw(all_routes));
}

my $uuid = Data::UUID->new;

my $pgtmp = mk_tmp_db() or BAIL_OUT("failed to create test database");
my $dbh = DBI->connect( $pgtmp->dsn );

my $t = Test::Mojo->new(Conch => { 
	pg      => $pgtmp->uri,
	secrets => [ "********" ]
});

all_routes($t->app->routes);

$t->get_ok("/ping")->status_is(200)->json_is('/status' => 'ok');

$t->post_ok("/login" => json => {
	user     => 'conch', 
	password => 'conch'
})->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;

isa_ok($t->tx->res->cookie('conch'), 'Mojo::Cookie::Response');

######################
### USER
$t->get_ok("/me")->status_is(204)->content_is("");
$t->get_ok("/user/me/settings")->status_is(200)->json_is('', {});
$t->get_ok("/user/me/settings/BAD")->status_is(404)->json_is('', {
	error => "No such setting 'BAD'",
});
$t->post_ok("/user/me/settings/TEST" => json => {
	"NOTTEST" => "test",
})->status_is(400)->json_is({
	error => "Setting key in request object must match name in the URL ('TEST')",
});

$t->post_ok("/user/me/settings/TEST" => json => {
	"TEST" => "test",
})->status_is(200)->content_is('');

$t->get_ok("/user/me/settings/TEST")->status_is(200)->json_is('', {
	"TEST" => "test",
});

$t->get_ok("/user/me/settings")->status_is(200)->json_is('', {
	"TEST" => "test"
});

$t->post_ok("/user/me/settings/TEST2" => json => {
	"TEST2" => "test",
})->status_is(200)->content_is('');

$t->get_ok("/user/me/settings/TEST2")->status_is(200)->json_is('', {
	"TEST2" => "test",
});

$t->get_ok("/user/me/settings")->status_is(200)->json_is('', {
	"TEST" => "test",
	"TEST2" => "test",
});

$t->delete_ok("/user/me/settings/TEST")->status_is(204)->content_is('');
$t->get_ok("/user/me/settings")->status_is(200)->json_is('', {
	"TEST2" => "test",
});

$t->delete_ok("/user/me/settings/TEST2")->status_is(204)->content_is('');

$t->get_ok("/user/me/settings")->status_is(200)->json_is('', {});
$t->get_ok("/user/me/settings/TEST")->status_is(404)->json_is('', {
	error => "No such setting 'TEST'",
});


######################
### WORKSPACES

$t->get_ok("/workspace/notauuid")->status_is(400);
TODO: {
	local $TODO = "API currently throws an exception when not-uuids are passed in";
	$t->content_like(qr/not sure/);
}

$t->get_ok('/workspace')->status_is(200)->json_is('/0/name', 'GLOBAL');

my $id = $t->tx->res->json->[0]{id};
BAIL_OUT("No workspace ID") unless $id;


$t->get_ok("/workspace/$id")->status_is(200);
$t->json_is('', {
	id   => $id,
	name => "GLOBAL",
	role => "Administrator",
	description => "Global workspace. Ancestor of all workspaces.",
}, 'Workspace v1 data contract');


$t->get_ok("/workspace/".$uuid->create_str())->status_is(404);


$t->get_ok("/workspace/$id/problem")->status_is(200)->json_is('', {
	failing    => {},
	unlocated  => {},
	unreported => {},
}, "Workspace Problem (empty) V1 Data Contract");

$t->get_ok("/workspace/$id/user")->status_is(200);
$t->json_is('', [{
	name  => "conch",
	email => 'conch@conch.joyent.us',
	role  => "Administrator",
}], "Workspace User v1 Data Contract");

$t->get_ok("/device/FAKE")->status_is(404);

######################
### SUBWORKSPACES
$t->get_ok("/workspace/$id/child")->status_is(200)->json_is('', []);
$t->post_ok("/workspace/$id/child" => json => {
	name => "test",
	description => "also test",
})->status_is(201);

my $sub_uuid = $t->tx->res->json->{id};
SKIP: {
	skip "Sub-workspace creation failed", 1 unless $sub_uuid;
	subtest "Sub-workspace" => sub {
		$t->get_ok("/workspace/$id/child")->status_is(200);
		$t->json_is('', [{
			id   => $sub_uuid,
			name => "test",
			role => "Administrator",
			description => "also test",
		}], "Subworkspace List V1 Data Contract");

		$t->get_ok("/workspace/$sub_uuid")->status_is(200);
		$t->json_is('', {
			id   => $sub_uuid,
			name => "test",
			role => "Administrator",
			description => "also test",
		}, "Subworkspace V1 Data Contract");
	};
};


######################
### ROOMS
$t->get_ok("/workspace/$id/room")->status_is(200)->json_is('', []);

######################
### RACKS
note("Variance: /rack in v1 returns a hash keyed by datacenter room id instead of an array");
$t->get_ok("/workspace/$id/rack")->status_is(200)->json_is('', {});

$t->get_ok("/workspace/$id/rack/notauuid")->status_is(400);
TODO: {
	local $TODO = "API currently throws an exception when not-uuids are passed in";
	$t->content_like(qr/not sure/);
}
$t->get_ok("/workspace/$id/rack/".$uuid->create_str())->status_is(404);


######################
### DEVICES
$t->get_ok("/workspace/$id/device")->status_is(200)->json_is('', []);

# /device/active redirects to /device so first make sure there is a redirect,
# then follow it and verify the results
$t->get_ok("/workspace/$id/device/active")->status_is(302);
my $temp = $t->ua->max_redirects;
$t->ua->max_redirects(1);
$t->get_ok("/workspace/$id/device/active")->status_is(200)->json_is('', []);
$t->ua->max_redirects($temp);

$t->get_ok("/hardware_product")->status_is(200)->json_is('',[]);



#### Load up data
for my $file (io->dir("../sql/test/")->sort->glob("*.sql")) {
	$dbh->do($file->all) or BAIL_OUT("Test SQL load failed");
}

# XXX 
$t->get_ok("/hardware_product")->status_is(200)->json_is('',[]);


### RELAYS
$t->get_ok("/workspace/$id/relay")->status_is(200)->json_is('', []);

#####
$t->post_ok("/logout")->status_is(204);
$t->get_ok("/workspace")->status_is(401);

  
done_testing();

