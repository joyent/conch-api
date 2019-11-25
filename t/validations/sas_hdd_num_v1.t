use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::SasHddNum',
    hardware_product => {
        name    => 'Test Product',
    },
    cases => [
        {
            description => 'No Data yields no success',
            data        => {},
        },
    ]
);

test_validation(
    'Conch::Validation::SasHddNum',
    hardware_product => {
        name    => 'Test Product',
        sas_hdd_num => 2,
    },
    cases => [
        {
            description => 'Failure when no SAS HDDs and sas_hdd_num in hardware_product',
            data        => {
                disks => {}
            },
            failure_num => 1
        },
        {
            description => 'Success when enough SAS HDDs',
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
            description => 'Failure when not enough SAS HDDs',
            data        => {
                disks => {
                    DISK1 => {
                        drive_type => 'SAS_HDD'
                    },
                    BADDISK => {
                        drive_type => 'RAID_LUN'
                    },
                }
            },
            failure_num => 1
        },
    ]
);
done_testing;
