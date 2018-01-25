use Mojo::Base -strict;
use Test::More;

use_ok("Conch::Class::Workspace");
new_ok('Conch::Class::Workspace');

my $ws = new_ok('Conch::Class::Workspace', [
	id => 'id',
	name => 'name',
	description => 'description',
	parent_workspace_id => 'parent_workspace_id'
]);

is(
	$ws->as_v1_json->{parent_workspace_id}, 
	undef, 
	'parent workspace ID not published'
);

done_testing();
