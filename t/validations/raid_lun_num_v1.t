use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::RaidLunNum',
	hardware_product => {
		name    => 'Test Product',
		profile => {}
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
	'Conch::Validation::RaidLunNum',
	hardware_product => {
		name    => 'Test Product',
		profile => { raid_lun_num => 2 }
	},
	cases => [
		{
			description => 'Failure when no RAID LUNs but raid_lun_num in profile',
			data        => {
				disks => {}
			},
			failure_num => 1
		},
		{
			description => 'Success when enough RAID LUNs',
			data        => {
				disks => {
					LUN1 => {
						drive_type => 'RAID_LUN'
					},
					LUN2 => {
						drive_type => 'RAID_LUN'
					},
				}
			},
			success_num => 1
		},
		{
			description => 'Failure when not enough RAID LUNs',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'RAID_LUN'
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
