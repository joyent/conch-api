use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::SlogSlot',
	hardware_product => {
		name => 'Test Product',
	},
	cases => [
		{
			description => 'No Data',
			data        => {},
			dies        => 1
		},
		{
			description => 'No SSD disk, no results',
			data        => {
				disks => {
					DEADBEEF => {
						device     => "sda",
						drive_type => "SAS_HDD",
						health     => "OK",
						transport  => "sas",
						slot       => 0
					},
					COFFEE => {
						device     => "sda",
						drive_type => "SAS_HDD",
						health     => "OK",
						transport  => "sas",
						slot       => 1
					},
				}
			},
			success_num => 0,
			failure_num => 0,
		},
		{
			description => 'Single SSD disk in slot 0',
			data        => {
				disks => {
					DEADBEEF => {
						device     => "sda",
						drive_type => "SAS_SSD",
						health     => "OK",
						transport  => "sas",
						slot       => 0
					},
					COFFEE => {
						device     => "sda",
						drive_type => "SAS_HDD",
						health     => "OK",
						transport  => "sas",
						slot       => 1
					},
				}
			},
			success_num => 1,
		},
		{
			description => 'Single SSD disk not in slot 0',
			data        => {
				disks => {
					DEADBEEF => {
						device     => "sda",
						drive_type => "SAS_SSD",
						health     => "OK",
						transport  => "sas",
						slot       => 2
					},
					COFFEE => {
						device     => "sda",
						drive_type => "SAS_HDD",
						health     => "OK",
						transport  => "sas",
						slot       => 1
					},
				}
			},
			failure_num => 1,
		},
		{
			description => "No results when multiple SSDs",
			data        => {
				disks => {
					DEADBEEF => {
						device     => "sda",
						drive_type => "SAS_SSD",
						health     => "OK",
						transport  => "sas",
						slot       => 2
					},
					COFFEE => {
						device     => "sda",
						drive_type => "SAS_SSD",
						health     => "OK",
						transport  => "sas",
						slot       => 1
					},
				}
			},
			success_num => 0,
			failure_num => 0,
		},
	]
);

done_testing();
