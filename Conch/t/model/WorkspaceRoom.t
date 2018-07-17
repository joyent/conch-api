use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);
use Conch::Pg;

use_ok("Conch::Model::Workspace");
use_ok("Conch::Model::WorkspaceRoom");

my $pgtmp = mk_tmp_db() or die;
Conch::Pg->new( $pgtmp->uri );

my $ws_model = new_ok( "Conch::Model::Workspace" );
my $global_ws = $ws_model->lookup_by_name('GLOBAL');

new_ok('Conch::Model::WorkspaceRoom');
my $ws_room_model = new_ok( "Conch::Model::WorkspaceRoom" );

subtest "Get list of workspace rooms" => sub {
	my $workspace_rooms = $ws_room_model->list( $global_ws->id );
	isa_ok( $workspace_rooms, 'ARRAY' );
	is( scalar @$workspace_rooms, 0 );
};

done_testing();
