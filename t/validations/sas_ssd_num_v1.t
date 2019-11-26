use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::SasSsdNum',
    device => {
        hardware_product => {
            name    => 'Test Product',
        },
    },
    cases => [
        {
            description => 'No Data yields no success',
            data        => {},
        },
    ]
);

test_validation(
    'Conch::Validation::SasSsdNum',
    device => {
        hardware_product => {
            name    => 'Test Product',
            sas_ssd_num => 2,
        },
    },
    cases => [
        {
            description => 'Failure when no SAS SSDs but sas_ssd_num in hardware_product',
            data        => {
                disks => {}
            },
            failure_num => 1
        },
        {
            description => 'Success when enough SAS SSDs',
            data        => {
                disks => {
                    DISK1 => {
                        drive_type => 'SAS_SSD'
                    },
                    DISK2 => {
                        drive_type => 'SAS_SSD'
                    },
                }
            },
            success_num => 1
        },
        {
            description => 'Failure when not enough SAS SSDs',
            data        => {
                disks => {
                    DISK1 => {
                        drive_type => 'SAS_SSD'
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
done_testing;
