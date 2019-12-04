use v5.26;
use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

use lib 't/lib';

subtest 'database object construction' => sub {
    test_validation(
        'Conch::Validation::TestConchValidationTester',
        cases => [
            {
                description => 'null test',
                error_num => 0,
            },
            {
                description => 'did not request device (but got a generic one)',
                data => { subname => '_device_inflation' },
                success_num => 2,
            },
            {
                description => 'did not request hardware_product (but got a generic one)',
                data => { subname => '_hardware_product_inflation' },
                success_num => 3,
            },
            {
                description => 'did not request device_location',
                data => { subname => '_has_no_device_location' },
                success_num => 1,
                error_num => 1,
            },
            {
                description => 'did not request device_settings',
                data => { subname => '_has_no_device_settings' },
                success_num => 1,
            },
        ],
    );

    test_validation(
        'Conch::Validation::TestConchValidationTester',
        device => {
            serial_number => 'my device',
        },
        cases => [
            {
                description => 'device inflation',
                data => { subname => '_device_inflation', device_serial_number => 'my device' },
                success_num => 2,
            },
            {
                description => 'did not request hardware_product (but got a generic one)',
                data => { subname => '_hardware_product_inflation' },
                success_num => 3,
            },
            {
                description => 'did not request device_location',
                data => { subname => '_has_no_device_location' },
                success_num => 1,
                error_num => 1,
            },
        ],
    );

    test_validation(
        'Conch::Validation::TestConchValidationTester',
        device => {
            hardware_product => { name => 'my product' },
        },
        cases => [
            {
                description => 'did not request device (but got a generic one)',
                data => { subname => '_device_inflation' },
                success_num => 2,
            },
            {
                description => 'hardware_product inflation',
                data => { subname => '_hardware_product_inflation', hardware_product_name => 'my product' },
                success_num => 3,
            },
            {
                description => 'did not request device_location',
                data => { subname => '_has_no_device_location' },
                success_num => 1,
                error_num => 1,
            },
        ],
    );

    test_validation(
        'Conch::Validation::TestConchValidationTester',
        device => {
            hardware_product => {
                dimms_num => 4,
            },
        },
        cases => [
            {
                description => 'did not request device (but got a generic one)',
                data => { subname => '_device_inflation' },
                success_num => 2,
            },
            {
                description => 'hardware_product inflation',
                data => { subname => '_hardware_product_inflation' },
                success_num => 3,
            },
            {
                description => 'did not request device_location',
                data => { subname => '_has_no_device_location' },
                success_num => 1,
                error_num => 1,
            },
        ],
    );

    test_validation(
        'Conch::Validation::TestConchValidationTester',
        device => {
            device_location => {
                rack_unit_start => 2,
                # rack_layout is implicit
            },
        },
        cases => [
            {
                description => 'did not request device (but got a generic one)',
                data => { subname => '_device_inflation' },
                success_num => 2,
            },
            {
                description => 'did not request hardware_product (but got a generic one)',
                data => { subname => '_hardware_product_inflation' },
                success_num => 3,
            },
            {
                description => 'device_location inflation',
                data => { subname => '_device_location_inflation', rack_unit_start => 2 },
                success_num => 3,
            },
            {
                description => 'when rack_layout is defined, it gets a distinct hardware_product',
                data => { subname => '_rack_layout_different_hardware_product' },
                success_num => 1,
            },
        ],
    );

    test_validation(
        'Conch::Validation::TestConchValidationTester',
        device => {
            device_location => {
                rack_unit_start => 3,
                rack => {
                    name => 'my rack',
                },
                rack_layout => {
                    hardware_product => { name => 'product B' },
                },
            },
        },
        cases => [
            {
                description => 'did not request device (but got a generic one)',
                data => { subname => '_device_inflation' },
                success_num => 2,
            },
            {
                description => 'did not request device hardware_product (but got a generic one)',
                data => { subname => '_hardware_product_inflation' },
                success_num => 3,
            },
            {
                description => 'device_location inflation',
                data => { subname => '_device_location_inflation', rack_unit_start => 3 },
                success_num => 3,
            },
            {
                description => 'rack inflation',
                data => { subname => '_rack_inflation', rack_unit_start => 3, rack_name => 'my rack' },
                success_num => 2,
            },
            {
                description => 'explicit hardware_product for rack_layout is distinct',
                data => { subname => '_rack_layout_different_hardware_product' },
                success_num => 1,
            },
        ],
    );

    test_validation(
        'Conch::Validation::TestConchValidationTester',
        device => {
            device_settings => { foo => 'bar' },
        },
        cases => [
            {
                description => 'did not request device (but got a generic one)',
                data => { subname => '_device_inflation' },
                success_num => 2,
            },
            {
                description => 'did not request hardware_product (but got a generic one)',
                data => { subname => '_hardware_product_inflation' },
                success_num => 3,
            },
            {
                description => 'did not request device_location',
                data => { subname => '_has_no_device_location' },
                success_num => 1,
                error_num => 1,
            },
            {
                description => 'device_settings storage',
                data => { subname => '_device_settings_storage' },
                success_num => 1,
            },
        ],
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
