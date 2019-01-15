use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::RamTotal',
	hardware_product => {
		name => 'Test Product',
		profile => { ram_total => 128 }
	},
	cases => [
		{
			description => 'No data yields no success',
			data        => {},
		},
		{
			description => 'No memory total yields no success',
			data        => { memory => {} },
		},
		{
			description => 'Wrong memory total fails',
			data        => { memory => { total => 64 } },
			failure_num => 1
		},
		{
			description => 'Correct memory total success',
			data        => { memory => { total => 128 } },
			success_num => 1
		},
	]
);

done_testing();
