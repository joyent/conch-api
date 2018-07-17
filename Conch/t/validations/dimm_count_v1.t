use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation;

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

test_validation(
	'Conch::Validation::DimmCount',
	hardware_product => {
		name    => 'Joyent-Storage-Platform-7001',
		profile => {}
	},
	cases => [
		{
			description => 'Incorrect DIMM count for Joyent Storage 7001',
			data        => { 'memory' => { count => 7 } },
			failure_num => 1
		},
		{
			description => '1 of 2 correct DIMM count for Joyent Storage 7001',
			data        => { 'memory' => { count => 8 } },
			success_num => 1
		},
		{
			description => '>8 incorrect DIMM count for Joyent Storage 7001',
			data        => { 'memory' => { count => 15 } },
			failure_num => 1
		},
		{
			description => '2 of 2 correct DIMM count for Joyent Storage 7001',
			data        => { 'memory' => { count => 16 } },
			success_num => 1
		},
	]
);

done_testing();
