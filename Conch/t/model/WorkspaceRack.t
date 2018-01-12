use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Conch::Model::Workspace;
use Conch::Model::WorkspaceRack;

use Data::Printer;
use Data::UUID;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

my $ws_model = Conch::Model::Workspace->new( pg => $pg );
my $global_ws = $ws_model->lookup_by_name('GLOBAL')->value;

new_ok('Conch::Model::WorkspaceRack');
my $ws_rack_model = Conch::Model::WorkspaceRack->new( pg => $pg );

subtest "Add rack to workspace" => sub {
  can_ok( $ws_rack_model, 'add_to_workspace' );
};

subtest "Remove rack from workspace" => sub {
  can_ok( $ws_rack_model, 'remove_from_workspace');
};

subtest "Get list of workspace racks" => sub {
  can_ok( $ws_rack_model, 'list' );
  my $workspace_racks = $ws_rack_model->list( $global_ws->id );
  isa_ok( $workspace_racks, 'HASH' );
};

subtest "Get workspace rack by ID" => sub {
  can_ok( $ws_rack_model, 'lookup' );
  my $workspace_rack = $ws_rack_model->lookup( $global_ws->id, $uuid->create_str() );
  isa_ok( $workspace_rack, 'Attempt::Fail' );
};

subtest "Get workspace rack layout" => sub {
  can_ok( $ws_rack_model, 'rack_layout' );
};


done_testing();

