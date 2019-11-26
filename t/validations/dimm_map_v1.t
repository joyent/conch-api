use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::DimmMap',
    device => {
        hardware_product => {
            name => 'Test Product',
            specification => '{
                "chassis": { "memory":{ "dimms": [
                    { "slot": "P1-DIMMA1" },
                    { "slot": "P1-DIMMB1" }
                ] } }
            }'
        },
    },
    cases => [
        {
            description => 'Correctly populated',
            data => {
                dimms => [
                    {
                        'memory-locator'       => "P1-DIMMA1",
                        'memory-serial-number' => '12345'
                    },
                    {
                        'memory-locator'       => "P1-DIMMB1",
                        'memory-serial-number' => '67890'
                    }
                ]
            },
            success_num => 1
        },
        {
            description => 'Failure when missing one DIMM',
            data => {
                dimms => [
                    {
                        'memory-locator'       => "P1-DIMMA1",
                        'memory-serial-number' => '12345'
                    }
                ]
            },
            failure_num => 1
        },
        {
            description => 'Incorrectly populated',
            data => {
                dimms => [
                    {
                        'memory-locator'       => "P1-DIMMA1",
                        'memory-serial-number' => '12345'
                    },
                    {
                        'memory-locator'       => "P1-DIMMD1",
                        'memory-serial-number' => '67890'
                    }
                ]
            },
            failure_num => 1
        },

    ]
);
done_testing;
