use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use_ok("Conch::Model::Workspace");
use_ok("Conch::Model::WorkspaceRoom");

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $ws_model = new_ok("Conch::Model::Workspace", [ pg => $pg ]);
my $global_ws = $ws_model->lookup_by_name('GLOBAL');

new_ok('Conch::Model::WorkspaceRoom');
my $ws_room_model = new_ok("Conch::Model::WorkspaceRoom", [ pg => $pg ]);

subtest "Get list of workspace rooms" => sub {
  my $workspace_rooms = $ws_room_model->list( $global_ws->id );
  isa_ok( $workspace_rooms, 'ARRAY' );
  is( scalar @$workspace_rooms, 0 );
};

done_testing();
