use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);

use Conch::Pg;

use Conch::Model::WorkspaceRack;

use Data::Printer;
use Data::UUID;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
Conch::Pg->new( $pgtmp->uri );
my $schema = Test::ConchTmpDB->schema($pgtmp);

my $uuid = Data::UUID->new;

my $global_ws = $schema->resultset('Workspace')->find({ name => 'GLOBAL' });

new_ok('Conch::Model::WorkspaceRack');
my $ws_rack_model = Conch::Model::WorkspaceRack->new();

isa_ok( $ws_rack_model->list( $global_ws->id ),
	'HASH', "Get list of workspaces" );

subtest "Get workspace rack by ID" => sub {
	my $workspace_rack =
		$ws_rack_model->lookup( $global_ws->id, $uuid->create_str() );
	is( $workspace_rack, undef, "Bad lookup fails" );
};

TODO: {
	local $TODO = "Untested sections";

	fail("Test 'add rack to workspace'");
	fail("Test 'remove rack to workspace'");

	fail("Test 'get workspace rack layout'");
}

done_testing();

