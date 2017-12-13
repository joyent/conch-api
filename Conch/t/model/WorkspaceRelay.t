use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Mojo::Conch::Model::Workspace;
use Mojo::Conch::Model::WorkspaceRelay;

use Data::Printer;
use Data::UUID;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

my $ws_model = Mojo::Conch::Model::Workspace->new( pg => $pg );
my $global_ws = $ws_model->lookup_by_name('GLOBAL')->value;

new_ok('Mojo::Conch::Model::WorkspaceRelay');
my $ws_relay_model = Mojo::Conch::Model::WorkspaceRelay->new( pg => $pg );

done_testing();

