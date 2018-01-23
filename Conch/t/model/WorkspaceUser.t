use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use_ok("Conch::Model::User");
use_ok("Conch::Model::Workspace");
use_ok("Conch::Model::WorkspaceUser");

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $user_model = new_ok("Conch::Model::User", [
  pg => $pg,
]);
my $new_user = $user_model->create( 'foo@bar.com', 'password' );

my $ws_model = new_ok("Conch::Model::Workspace", [ pg => $pg ]);
my $global_ws = $ws_model->lookup_by_name('GLOBAL')->value;

$ws_model->add_user_to_workspace( $new_user->id, $global_ws->id, 1 );

new_ok('Conch::Model::WorkspaceUser');
my $ws_user_model = new_ok("Conch::Model::WorkspaceUser", [ pg => $pg ]);

subtest "Get list of workspace users" => sub {
  my $workspace_users = $ws_user_model->workspace_users($global_ws->id);
  isa_ok($workspace_users, 'ARRAY');
  is(scalar @$workspace_users, 2);
  isa_ok($workspace_users->[0], 'Conch::Class::WorkspaceUser');
};

done_testing();
