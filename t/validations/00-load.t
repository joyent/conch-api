use Mojo::Base -strict;
use Test::More;

use Conch::Validations;
use Conch::Model::Validation;

use Test::Conch;


my $t = Test::Conch->new(); # Runs Validations->load() for the first time
my $logger = $t->app->log;

my $num_validations = 0;
for my $m ( Submodules->find('Conch::Validation') ) {
	next if $m->{Module} eq 'Conch::Validation';
	$num_validations++;
}

my $loaded_validations = Conch::Model::Validation->list;

is(
	$num_validations,
	scalar $loaded_validations->@*,
	'Number of validations matches number in the system'
);

my $num_reloaded = Conch::Validations->load($logger);

is( $num_reloaded, 0, 'No new validations loaded' );

done_testing();

