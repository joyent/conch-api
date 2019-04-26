use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::SasSsdNum',
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
            description => 'No sas_ssd_num in profile. Assume 0',
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
        hardware_product_profile => { sas_ssd_num => 2 }
    },
    cases => [
        {
            description => 'Failure when no SAS SSDs but sas_ssd_num in profile',
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
done_testing();
