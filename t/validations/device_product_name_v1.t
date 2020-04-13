use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::DeviceProductName',
    device => {
        hardware_product => {
            sku => 'actual device sku',
            name => 'Test Product',
            generation_name => 'Joyent-G1',
        },
    },
    cases            => [
        {
            description => 'No data yields no success',
            data        => {},
        },
        {
            description => 'Correct product name; sku does not match device',
            data        => { 'product_name' => 'Joyent-G1', sku => 'foo' },
            failure_num => 1,
            success_num => 1
        },
        {
            description => 'Incorrect product name; sku does not match device',
            data        => { 'product_name' => 'Bad Product', sku => 'foo' },
            failure_num => 2,
        },
        {
            description => 'Correct product name; sku matches device',
            data        => { 'product_name' => 'Joyent-G1', sku => 'actual device sku' },
            success_num => 2,
        },
        {
            description => 'Incorrect product name; sku matches device',
            data        => { 'product_name' => 'Bad Product', sku => 'actual device sku' },
            failure_num => 1,
            success_num => 1,
        },
    ]
);

test_validation(
    'Conch::Validation::DeviceProductName',
    device => {
        hardware_product => {
            sku => 'actual device sku',
            name => 'Test Product',
        },
    },
    cases            => [
        {
            description => 'switch: correct product name; sku does not match device',
            data        => {
                device_type  => 'switch',
                sku          => 'foo',
                product_name => 'Test Product'
            },
            failure_num => 1,
            success_num => 1
        },
        {
            description => 'switch: incorrect product name; sku does not match device',
            data        => {
                device_type  => 'switch',
                sku          => 'foo',
                product_name => 'Test Product2'
            },
            failure_num => 2,
        }
    ]
);

test_validation(
    'Conch::Validation::DeviceProductName',
    device => {
        hardware_product => {
            sku => 'actual device sku',
            name => 'Test Product',
            generation_name => 'Joyent-G1',
        },
        device_location => {
            rack_unit_start => 3,
            rack => {
                name => 'my rack',
            },
            rack_layout => {
                hardware_product => {
                    sku => 'intended device sku',
                    name => 'foo',              # this is never used
                    generation_name => 'bar',   # this is never used
                },
            },
        },
    },
    cases            => [
        {
            description => 'No data yields no success',
            data        => {},
        },
        {
            description => 'Correct product name, wrong sku',
            data        => { 'product_name' => 'Joyent-G1', sku => 'foo' },
            success_num => 1,
            failure_num => 2,
        },
        {
            description => 'Incorrect product name, wrong device sku, right layout sku',
            data        => { 'product_name' => 'Bad Product', sku => 'intended device sku' },
            success_num => 1,
            failure_num => 2,
        },
        {
            description => 'Correct product name, wrong device sku, right layout sku',
            data        => { 'product_name' => 'Joyent-G1', sku => 'intended device sku' },
            success_num => 2,
            failure_num => 1,
        },
    ]
);

done_testing;
