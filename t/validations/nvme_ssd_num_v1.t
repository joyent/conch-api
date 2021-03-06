use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::NvmeSsdNum',
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
    'Conch::Validation::NvmeSsdNum',
    device => {
        hardware_product => {
            name    => 'Test Product',
            nvme_ssd_num => 2,
        },
    },
    cases => [
        {
            description => 'Failure when no NVMe SSDs but nvme_ssd_num in hardware_product',
            data        => {
                disks => {}
            },
            failure_num => 1
        },
        {
            description => 'Success when enough NVMe SSDs',
            data        => {
                disks => {
                    DISK1 => {
                        drive_type => 'NVME_SSD'
                    },
                    DISK2 => {
                        drive_type => 'NVME_SSD'
                    },
                }
            },
            success_num => 1
        },
        {
            description => 'Failure when not enough NVMe SSDs',
            data        => {
                disks => {
                    DISK1 => {
                        drive_type => 'NVME_SSD'
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
