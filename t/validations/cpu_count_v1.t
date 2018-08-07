use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::CpuCount',
	hardware_product => {
		profile => { cpu_num => 2 }
	},
	cases => [
		{
			description => 'Missing processor count hash',
			data        => { processor => 'foo' },
		},
		{
			description => 'Incorrect processor count',
			data        => { processor => { count => 1 } },
			failure_num => 1,
		},
		{
			description => 'Correct processor count',
			data        => { processor => { count => 2 } },
			success_num => 1,
		},
	]
);

done_testing();
