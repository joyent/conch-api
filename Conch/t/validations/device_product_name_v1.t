use Test::More;
use Test::Conch::Validation;

test_validation(
	'Conch::Validation::DeviceProductName',
	hardware_product => { name => 'Test Product' },
	cases            => [
		{
			description => 'No data dies',
			data        => {},
			dies        => 1
		},
		{
			description => 'Correct product name',
			data        => { 'product_name' => 'Test Product' },
			success_num => 1
		},
		{
			description => 'Incorrect product name',
			data        => { 'product_name' => 'Bad Product' },
			failure_num => 1
		}
	]
);

done_testing();
