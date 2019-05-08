use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::DeviceProductName',
    hardware_product => {
        name => 'Test Product',
        generation_name => 'Joyent-G1',
    },
    cases            => [
        {
            description => 'No data yields no success',
            data        => {},
        },
        {
            description => 'Correct product name',
            data        => { 'product_name' => 'Joyent-G1' },
            success_num => 1
        },
        {
            description => 'Incorrect product name',
            data        => { 'product_name' => 'Bad Product' },
            failure_num => 1
        }
    ]
);

test_validation(
    'Conch::Validation::DeviceProductName',
    hardware_product => {
        name => 'Test Product',
    },
    cases            => [
        {
            description => 'Correct product name',
            data        => {
                device_type  => 'switch',
                product_name => 'Test Product'
            },
            success_num => 1
        },
        {
            description => 'Incorrect product name',
            data        => {
                device_type  => 'switch',
                product_name => 'Test Product2'
            },
            failure_num => 1
        }
    ]
);

done_testing();
