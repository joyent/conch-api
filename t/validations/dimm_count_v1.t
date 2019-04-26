use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::DimmCount',
    hardware_product => {
        name    => 'Test Product',
        hardware_product_profile => { dimms_num => 2 }
    },
    cases => [
        {
            description => 'No data yields no success',
            data        => {},
        },
        {
            description => 'Incorrect DIMM count',
            data => {
                dimms => [
                    {
                        'memory-locator'       => "P1-DIMMA1",
                        'memory-serial-number' => '12345',
                        'memory-size'          => 16,
                        'memory-type'          => 'DDR4',
                    }
                ]
            },
            failure_num => 1
        },
        {
            description => 'Incorrect DIMM count, with some empty slots',
            data => {
                dimms => [
                    {
                        'memory-locator'       => "P1-DIMMA1",
                        'memory-serial-number' => '12345',
                        'memory-size'          => 16,
                        'memory-type'          => 'DDR4',
                    },
                    {
                        'memory-locator'       => "P1-DIMMB1",
                        'memory-serial-number' => 'Not specified',
                    },
                ]
            },
            failure_num => 1,
        },
        {
            description => 'Correct DIMM count',
            data => {
                dimms => [
                    {
                        'memory-locator'       => "P1-DIMMA1",
                        'memory-serial-number' => '12345',
                        'memory-size'          => 16,
                        'memory-type'          => 'DDR4',
                    },
                    {
                        'memory-locator'       => "P1-DIMMB1",
                        'memory-serial-number' => '67890',
                        'memory-size'          => 16,
                        'memory-type'          => 'DDR4',
                    }
                ]
            },
            success_num => 1
        },
    ]
);

done_testing();
