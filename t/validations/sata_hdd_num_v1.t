use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::SataHddNum',
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
    'Conch::Validation::SataHddNum',
    hardware_product => {
        name    => 'Test Product',
        hardware_product_profile => { sata_hdd_num => 2 }
    },
    cases => [
        {
            description => 'Failure when no SATA HDDs but sata_hdd_num in profile',
            data        => {
                disks => {}
            },
            failure_num => 1
        },
        {
            description => 'Success when enough SATA HDDs',
            data        => {
                disks => {
                    DISK1 => {
                        drive_type => 'SATA_HDD'
                    },
                    DISK2 => {
                        drive_type => 'SATA_HDD'
                    },
                }
            },
            success_num => 1
        },
        {
            description => 'Failure when not enough SATA HDDs',
            data        => {
                disks => {
                    DISK1 => {
                        drive_type => 'SATA_HDD'
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
done_testing;
