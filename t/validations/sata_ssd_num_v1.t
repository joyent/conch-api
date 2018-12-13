use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::SataSsdNum',
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
	'Conch::Validation::SataSsdNum',
	hardware_product => {
		name    => 'Test Product',
		profile => { sata_ssd_num => 2 }
	},
	cases => [
		{
			description => 'Failure when no SATA SSDs but sata_ssd_num in profile',
			data        => {
				disks => {}
			},
			failure_num => 1
		},
		{
			description => 'Success when enough SATA SSDs',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SATA_SSD'
					},
					DISK2 => {
						drive_type => 'SATA_SSD'
					},
				}
			},
			success_num => 1
		},
		{
			description => 'Failure when not enough SATA SSDs',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SATA_SSD'
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

# Special case for Joyent-Compute-Platform-3302.
# Should have either 8 or 16 SATA SSDs
test_validation(
	'Conch::Validation::SataSsdNum',
	hardware_product => {
		name    => 'Joyent-Compute-Platform-3302',
		profile => { sata_ssd_num => 2 }
	},
	cases => [
		{
			description => 'Failure when 2 SATA SSDs',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SATA_SSD'
					},
					BADDISK => {
						drive_type => 'SAS_HDD'
					},
				}
			},
			failure_num => 1
		},
		{
			description => 'Success when 8 SATA SSDs',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SATA_SSD'
					},
					DISK2 => {
						drive_type => 'SATA_SSD'
					},
					DISK3 => {
						drive_type => 'SATA_SSD'
					},
					DISK4 => {
						drive_type => 'SATA_SSD'
					},
					DISK5 => {
						drive_type => 'SATA_SSD'
					},
					DISK6 => {
						drive_type => 'SATA_SSD'
					},
					DISK7 => {
						drive_type => 'SATA_SSD'
					},
					DISK8 => {
						drive_type => 'SATA_SSD'
					},
				}
			},
			success_num => 1
		},
		{
			description => 'Success when 16 SATA SSDs',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SATA_SSD'
					},
					DISK2 => {
						drive_type => 'SATA_SSD'
					},
					DISK3 => {
						drive_type => 'SATA_SSD'
					},
					DISK4 => {
						drive_type => 'SATA_SSD'
					},
					DISK5 => {
						drive_type => 'SATA_SSD'
					},
					DISK6 => {
						drive_type => 'SATA_SSD'
					},
					DISK7 => {
						drive_type => 'SATA_SSD'
					},
					DISK8 => {
						drive_type => 'SATA_SSD'
					},
					DISK9 => {
						drive_type => 'SATA_SSD'
					},
					DISK10 => {
						drive_type => 'SATA_SSD'
					},
					DISK11 => {
						drive_type => 'SATA_SSD'
					},
					DISK12 => {
						drive_type => 'SATA_SSD'
					},
					DISK13 => {
						drive_type => 'SATA_SSD'
					},
					DISK14 => {
						drive_type => 'SATA_SSD'
					},
					DISK15 => {
						drive_type => 'SATA_SSD'
					},
					DISK16 => {
						drive_type => 'SATA_SSD'
					},
				}
			},
			success_num => 1
		},
	]
);
done_testing();
