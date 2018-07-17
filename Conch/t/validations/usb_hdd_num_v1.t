use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation;

test_validation(
	'Conch::Validation::UsbHddNum',
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
			description => 'No usb num in profile assume 0',
			data        => {
				disks => {}
			},
			success_num => 1
		},
	]
);

test_validation(
	'Conch::Validation::UsbHddNum',
	hardware_product => {
		name    => 'Test Product',
		profile => { usb_num => 2 }
	},
	cases => [
		{
			description => 'Failure when no usb disks and usb_num in profile',
			data        => {
				disks => {}
			},
			failure_num => 1
		},
		{
			description => 'success when enough usb disks',
			data        => {
				disks => {
					DEADBEEF => {
						transport => "usb",
					},
					COFFEE => {
						transport => "usb",
					},
				}
			},
			success_num => 1
		},
		{
			description => 'failure when not enough usb disks',
			data        => {
				disks => {
					DEADBEEF => {
						transport => "usb",
					},
					COFFEE => {
						transport => "sas",
					},
				}
			},
			failure_num => 1
		},
	]
);

done_testing();
