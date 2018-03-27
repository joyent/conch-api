use Test::More;
use Test::Conch::Validation;

test_validation(
	'Conch::Validation::CpuCount',
	hardware_product => {
		profile => { cpu_num => 2 }
	},
	cases => [
		{
			description => 'No data dies',
			data        => {},
			dies        => 1
		},
		{
			description => 'Missing processor count hash',
			data        => { processor => 'foo' },
			dies        => 1,
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
