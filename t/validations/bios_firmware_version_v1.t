use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::BiosFirmwareVersion',
    hardware_product => {
        name    => 'Test Product',
        hardware_product_profile => { bios_firmware => '1.2.3' }
    },
    cases => [
        {
            description => 'No data yields no successes',
            data        => {},
        },
        {
            description => 'bios_version should be string',
            data        => { bios_version => ['foobar'] },
        },
        {
            description => "bios_version doesn't match hw product definition",
            data        => { bios_version => '1.2' },
            failure_num => 1
        },
        {
            description => "bios_version matches hw product definition",
            data        => { bios_version => '1.2.3' },
            success_num => 1,
        },
    ]
);

done_testing();
