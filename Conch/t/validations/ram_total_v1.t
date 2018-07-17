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
			description => 'No data dies',
			data        => {},
			dies        => 1
		},
		{
			description => 'No memory total dies',
			data        => { memory => {} },
			dies        => 1
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

# Special case for Joyent-Storage-Platform-7001. Needs either 256 or 512
test_validation(
	'Conch::Validation::RamTotal',
	hardware_product => {
		name => 'Joyent-Storage-Platform-7001',
		profile => { ram_total => 128 } # doesn't matter
	},
	cases => [
		{
			description => 'Wrong memory total fails',
			data        => { memory => { total => 128 } },
			failure_num => 1
		},
		{
			description => '256 is computed correct memory total',
			data        => { memory => { total => 256 } },
			success_num => 1
		},
		{
			description => '512 is computed correct memory total',
			data        => { memory => { total => 512 } },
			success_num => 1
		},
		{
			description => '384 is wrong memory total',
			data        => { memory => { total => 384 } },
			failure_num => 1
		},
	]
);

done_testing();
