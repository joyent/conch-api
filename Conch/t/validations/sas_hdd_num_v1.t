use Test::More;
use Test::Conch::Validation;

test_validation(
	'Conch::Validation::SasHddNum',
	hardware_product => {
		name    => 'Test Product',
		profile => {}
	},
	cases => [
		{
			description => 'No Data',
			data        => {},
			dies        => 1
		},
		{
			description => 'No hdd num in profile assume 0',
			data        => {
				disks => {}
			},
			success_num => 1
		},
	]
);

test_validation(
	'Conch::Validation::SasHddNum',
	hardware_product => {
		name    => 'Test Product',
		profile => { sas_num => 2 }
	},
	cases => [
		{
			description => 'Failure when no SAS disks but sas_num in profile',
			data        => {
				disks => {}
			},
			failure_num => 1
		},
		{
			description => 'success when enough SAS disks',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SAS_HDD'
					},
					DISK2 => {
						drive_type => 'SAS_HDD'
					},
				}
			},
			success_num => 1
		},
		{
			description => 'failure when not enough SAS disks',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SAS_HDD'
					},
					BADDISK => {
						drive_type => 'SATA_HDD'
					},
				}
			},
			failure_num => 1
		},
	]
);
done_testing();
