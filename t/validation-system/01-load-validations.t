use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::ConchTmpDB qw(mk_tmp_db);
use Conch::Pg;
use Data::UUID;
use DDP;

use Conch::ValidationSystem;
use Conch::Model::Device;
use Conch::Model::Validation;
use Conch::Model::ValidationPlan;

my $uuid  = Data::UUID->new;
my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg    = Conch::Pg->new( $pgtmp->uri );

use Conch::Log;
my $logger = Conch::Log->new(level => 'warn');

my $num_validations_loaded =
	Conch::ValidationSystem->load_validations($logger);

my $loaded_validations = Conch::Model::Validation->list;

is(
	$num_validations_loaded,
	scalar $loaded_validations->@*,
	'Number of validations loaded matches number in system'
);

my $num_validations_reloaded =
	Conch::ValidationSystem->load_validations($logger);

is( $num_validations_reloaded, 0, 'No new validations loaded' );

done_testing();

