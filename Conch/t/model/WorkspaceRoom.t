use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Conch::Model::Workspace;
use Conch::Model::WorkspaceRoom;

use Data::Printer;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $ws_model = Conch::Model::Workspace->new( pg => $pg );
my $global_ws = $ws_model->lookup_by_name('GLOBAL')->value;

new_ok('Conch::Model::WorkspaceRoom');
my $ws_room_model = Conch::Model::WorkspaceRoom->new( pg => $pg );

subtest "Get list of workspace rooms" => sub {
  can_ok( $ws_room_model, 'list' );
  my $workspace_rooms = $ws_room_model->list( $global_ws->id );
  isa_ok( $workspace_rooms, 'ARRAY' );
  is( scalar @$workspace_rooms, 0 );
};

done_testing();
