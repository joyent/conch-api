use Test::More;
use Test::Conch::Validation;

test_validation(
	'Conch::Validation::CpuTemperature',
	hardware_product => {
		profile => { cpu_num => 2 }
	},
	cases => [
		{
			description => 'No data',
			data        => {},
			dies        => 1
		},
		{
			description => 'No temperature hash',
			data        => { temp => 'foo' },
			dies        => 1,
		},
		{
			description => 'Only one CPU temperature',
			data        => { temp => { cpu0 => 10 } },
			dies        => 1,
		},
		{
			description => 'Only one CPU temperature',
			data        => { temp => { cpu1 => 20 } },
			dies        => 1,
		},
		{
			description => 'CPU temperatures under threshodl',
			data        => { temp => { cpu0 => 10, cpu1 => 20 } },
			success_num => 2,
		},
		{
			description => 'One CPU temperature over threshold',
			data        => { temp => { cpu0 => 100, cpu1 => 20 } },
			success_num => 1,
			failure_num => 1,
		},
		{
			description => 'Both CPU temperature over threshold',
			data        => { temp => { cpu0 => 100, cpu1 => 200 } },
			failure_num => 2,
		},
	]
);

done_testing();
