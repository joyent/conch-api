use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::UsbHddNum',
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
        hardware_product_profile => { usb_num => 2 }
    },
    cases => [
        {
            description => 'Failure when no USB disks and usb_num in profile',
            data        => {
                disks => {}
            },
            failure_num => 1
        },
        {
            description => 'Success when enough USB disks',
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
            description => 'Failure when not enough USB disks',
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
