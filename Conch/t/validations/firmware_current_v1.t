use Test::More;
use Test::Conch::Validation;

test_validation(
	'Conch::Validation::FirmwareCurrent',
	cases => [
		{
			description => 'No device settings fails',
			failure_num => 1,
		},
	]
);

test_validation(
	'Conch::Validation::FirmwareCurrent',
	device_settings => {
		firmware => 'updating'
	},
	cases => [
		{
			description => '"updating" firmware fails',
			failure_num => 1,
		},
	]
);

test_validation(
	'Conch::Validation::FirmwareCurrent',
	device_settings => {
		firmware => 'current'
	},
	cases => [
		{
			description => '"current" firmware fails',
			success_num => 1,
		},
	]
);

done_testing();

