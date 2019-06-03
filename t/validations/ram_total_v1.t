use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::RamTotal',
    hardware_product => {
        name => 'Test Product',
        hardware_product_profile => { ram_total => 128 }
    },
    cases => [
        {
            description => 'No data yields no success',
            data        => {},
        },
        {
            description => 'No memory total yields no success',
            data        => { dimms => [] },
        },
        {
            description => 'Wrong memory total fails',
            data => {
                dimms => [
                    {
                        'memory-locator'       => "P1-DIMMA1",
                        'memory-serial-number' => '12345',
                        'memory-size'          => 64,
                    }
                ]
            },
            failure_num => 1
        },
        {
            description => 'Correct memory total success',
            data => {
                dimms => [
                    {
                        'memory-locator'       => "P1-DIMMA1",
                        'memory-serial-number' => '12345',
                        'memory-size'          => 64,
                    },
                    {
                        'memory-locator'       => "P1-DIMMB1",
                        'memory-serial-number' => '67890',
                        'memory-size'          => 64,
                    }
                ]
            },
            success_num => 1
        },
    ]
);

done_testing;
