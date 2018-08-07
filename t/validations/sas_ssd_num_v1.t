use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::SasSsdNum',
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
			description => 'No ssd num in profile assume 0',
			data        => {
				disks => {}
			},
			success_num => 1
		},
	]
);

test_validation(
	'Conch::Validation::SasSsdNum',
	hardware_product => {
		name    => 'Test Product',
		profile => { ssd_num => 2 }
	},
	cases => [
		{
			description => 'Failure when no ssd disks and ssd_num in profile',
			data        => {
				disks => {}
			},
			failure_num => 1
		},
		{
			description => 'success when enough ssd disks',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SAS_SSD'
					},
					DISK2 => {
						drive_type => 'SATA_SSD'
					},
				}
			},
			success_num => 1
		},
		{
			description => 'failure when not enough ssd disks',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SAS_SSD'
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

# special case for Joyent-Compute-Platform-3302. Should have either 8 or 16 disks
test_validation(
	'Conch::Validation::SasSsdNum',
	hardware_product => {
		name    => 'Joyent-Compute-Platform-3302',
		profile => { ssd_num => 2 }                  # doesn't matter
	},
	cases => [
		{
			description => 'failure when 2 ssd disks',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SAS_SSD'
					},
					BADDISK => {
						drive_type => 'SAS_HDD'
					},
				}
			},
			failure_num => 1
		},
		{
			description => 'success when 8 ssd disks',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SAS_SSD'
					},
					DISK2 => {
						drive_type => 'SATA_SSD'
					},
					DISK3 => {
						drive_type => 'SAS_SSD'
					},
					DISK4 => {
						drive_type => 'SATA_SSD'
					},
					DISK5 => {
						drive_type => 'SAS_SSD'
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
			description => 'success when 16 ssd disks',
			data        => {
				disks => {
					DISK1 => {
						drive_type => 'SAS_SSD'
					},
					DISK2 => {
						drive_type => 'SATA_SSD'
					},
					DISK3 => {
						drive_type => 'SAS_SSD'
					},
					DISK4 => {
						drive_type => 'SATA_SSD'
					},
					DISK5 => {
						drive_type => 'SAS_SSD'
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
						drive_type => 'SAS_SSD'
					},
					DISK10 => {
						drive_type => 'SATA_SSD'
					},
					DISK11 => {
						drive_type => 'SAS_SSD'
					},
					DISK12 => {
						drive_type => 'SATA_SSD'
					},
					DISK13 => {
						drive_type => 'SAS_SSD'
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
