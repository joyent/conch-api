use Mojo::Base -strict;
use Test::More;

use_ok("Conch::Class::WorkspaceUser");
new_ok('Conch::Class::WorkspaceUser');

new_ok(
	"Conch::Class::WorkspaceUser",
	[
		id   => 'id',
		name => 'name',
		role => 'role'
	]
);

done_testing();
