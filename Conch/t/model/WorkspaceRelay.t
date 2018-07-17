use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);

use Conch::Model::Workspace;
use Conch::Model::WorkspaceRelay;

use Data::Printer;
use Data::UUID;

my $pgtmp = mk_tmp_db() or die;
Conch::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

my $ws_model = Conch::Model::Workspace->new();
my $global_ws = $ws_model->lookup_by_name('GLOBAL');

new_ok('Conch::Model::WorkspaceRelay');
my $ws_relay_model = Conch::Model::WorkspaceRelay->new();

done_testing();

