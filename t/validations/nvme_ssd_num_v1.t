use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::NvmeSsdNum',
	hardware_product => {
		name    => 'Test Product',
		hardware_product_profile => {}
	},
	cases => [
		{
			description => 'No Data yields no success',
			data        => {},
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
	'Conch::Validation::NvmeSsdNum',
	hardware_product => {
		name    => 'Test Product',
		hardware_product_profile => { nvme_ssd_num => 2 }
	},
	cases => [
		{
			description => 'Failure when no NVMe SSDs but nvme_ssd_num in profile',
			data        => {
				disks => {}
			},
			failure_num => 1
		},
		{
			description => 'Success when enough NVMe SSDs',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'NVME_SSD'
					},
					DISK2 => {
						drive_type => 'NVME_SSD'
					},
				}
			},
			success_num => 1
		},
		{
			description => 'Failure when not enough NVMe SSDs',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'NVME_SSD'
					},
					BADDISK => {
						drive_type => 'SAS_HDD'
					},
				}
			},
			failure_num => 1
		},
	]
);
done_testing();
