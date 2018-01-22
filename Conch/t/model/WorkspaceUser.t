use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Conch::Model::User;
use Conch::Model::Workspace;
use Conch::Model::WorkspaceUser;

use Data::Printer;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $user_model = Conch::Model::User->new(
  hash_password         => sub { reverse shift },
  pg                    => $pg,
  validate_against_hash => sub { reverse(shift) eq shift }
);
my $new_user = $user_model->create( 'foo@bar.com', 'password' )->value;

my $ws_model = Conch::Model::Workspace->new( pg => $pg );
my $global_ws = $ws_model->lookup_by_name('GLOBAL')->value;

$ws_model->add_user_to_workspace( $new_user->id, $global_ws->id, 1 );

new_ok('Conch::Model::WorkspaceUser');

my $ws_user_model = Conch::Model::WorkspaceUser->new( pg => $pg );

subtest "Get list of workspace users" => sub {
  my $workspace_users = $ws_user_model->workspace_users($global_ws->id);
  isa_ok($workspace_users, 'ARRAY');
  is(scalar @$workspace_users, 2);
  isa_ok($workspace_users->[0], 'Conch::Class::WorkspaceUser');
};

done_testing();
