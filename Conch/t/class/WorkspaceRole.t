use Mojo::Base -strict;
use Test::More;

use_ok("Conch::Class::WorkspaceRole");
new_ok('Conch::Class::WorkspaceRole');

new_ok(
	"Conch::Class::WorkspaceRole", [
		id   => 'id',
		name => 'name',
		role => 'role'
	]
);

fail("Test more than constructors");
done_testing();

