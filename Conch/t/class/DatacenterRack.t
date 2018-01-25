use Mojo::Base -strict;
use Test::More;

use_ok("Conch::Class::DatacenterRack");
new_ok('Conch::Class::DatacenterRack');

my %attrs = (
	id                 => 'id',
	name               => 'name',
	role_name          => 'role_name',
	datacenter_room_id => 'dc',
);

my $rack = new_ok( "Conch::Class::DatacenterRack", [%attrs] );

is( $rack->id,        $attrs{id},        "ID value check" );
is( $rack->name,      $attrs{name},      "Name value check" );
is( $rack->role_name, $attrs{role_name}, "Role name value check" );
is(
	$rack->datacenter_room_id,
	$attrs{datacenter_room_id},
	"Datacenter Room ID value check"
);

TODO: {
	local $TODO = "We never actually use as_v1_json in the codebase";
	is_deeply( $rack->as_v1_json, \%attrs );
}

done_testing();

