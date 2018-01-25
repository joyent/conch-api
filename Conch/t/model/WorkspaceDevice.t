use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;
use Data::UUID;

use_ok("Conch::Model::WorkspaceDevice");

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

new_ok('Conch::Model::WorkspaceDevice');

my $device_model = new_ok( "Conch::Model::WorkspaceDevice", [ pg => $pg ] );

subtest "Get list of workspace devices" => sub {
	isa_ok( $device_model->list( $uuid->create_str ), 'ARRAY' );
};

done_testing();

