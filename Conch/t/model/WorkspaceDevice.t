use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Data::UUID;

use Conch::Pg;

use_ok("Conch::Model::WorkspaceDevice");

my $pgtmp = mk_tmp_db() or die;
Conch::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

new_ok('Conch::Model::WorkspaceDevice');

my $device_model = new_ok( "Conch::Model::WorkspaceDevice" );

subtest "Get list of workspace devices" => sub {
	isa_ok( $device_model->list( $uuid->create_str ), 'ARRAY' );
};

done_testing();

