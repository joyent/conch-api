use Mojo::Base -strict;
use Test::More;

use_ok("Conch::Class::User");
new_ok('Conch::Class::User');

new_ok("Conch::Class::User", [
	id   => 'id',
	name => 'name',
	password_hash => 'hash'
]);

fail("Test more than constructors");

done_testing();
