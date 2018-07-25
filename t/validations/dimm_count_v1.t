use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::DimmCount',
	hardware_product => {
		name    => 'Test Product',
		profile => { dimms_num => 8 }
	},
	cases => [
		{
			description => 'No data dies',
			data        => {},
			dies        => 1
		},
		{
			description => 'Iconrrect DIMM count',
			data        => { 'memory' => { count => 1 } },
			failure_num => 1
		},
		{
			description => 'Correct DIMM count',
			data        => { 'memory' => { count => 8 } },
			success_num => 1
		},
	]
);

done_testing();
