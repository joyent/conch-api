use Mojo::Base -strict;
use Test::More;

use_ok("Conch::Class::DatacenterRoom");
new_ok('Conch::Class::DatacenterRoom');

new_ok("Conch::Class::DatacenterRoom", [
	id    => 'id',
	az    => 'az',
	alias => 'alias',
	vendor_name => 'vendor_name'
]);

done_testing();

