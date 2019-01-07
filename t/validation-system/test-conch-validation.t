use v5.26;
use strict;
use warnings;
use Test::More;
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
                description => 'did not request device',
                data => { subname => '_has_no_device' },
                success_num => 1,
            },
            {
                description => 'did not request hardware_product',
                data => { subname => '_has_no_hardware_product' },
                success_num => 1,
                error_num => 1,
            },
            {
                description => 'did not request hardware_product_profile',
                data => { subname => '_has_no_hardware_product_profile' },
                error_num => 1,
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
        device => { id => 'my device' },
        cases => [
            {
                description => 'device inflation',
                data => { subname => '_device_inflation', device_id => 'my device' },
                success_num => 1,
            },
            {
                description => 'did not request hardware_product',
                data => { subname => '_has_no_hardware_product' },
                success_num => 1,
                error_num => 1,
            },
            {
                description => 'did not request hardware_product_profile',
                data => { subname => '_has_no_hardware_product_profile' },
                error_num => 1,
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
        hardware_product => { name => 'my product' },
        cases => [
            {
                description => 'did not request device',
                data => { subname => '_has_no_device' },
                success_num => 1,
            },
            {
                description => 'hardware_product inflation',
                data => { subname => '_hardware_product_inflation', hardware_product_name => 'my product' },
                success_num => 2,
            },
            {
                description => 'did not request hardware_product_profile',
                data => { subname => '_has_no_hardware_product_profile' },
                success_num => 1,
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
        hardware_product => {
            hardware_product_profile => { rack_unit => 4 },
        },
        cases => [
            {
                description => 'did not request device',
                data => { subname => '_has_no_device' },
                success_num => 1,
            },
            {
                description => 'hardware_product inflation',
                data => { subname => '_hardware_product_inflation' },
                success_num => 2,
            },
            {
                description => 'hardware_product_profile inflation',
                data => { subname => '_hardware_product_profile_inflation', hardware_product_profile_rack_unit => 4 },
                success_num => 1,
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
        device_location => {
            rack_unit_start => 2,
            datacenter_rack_layouts => [ { rack_unit_start => 2 } ],
        },
        cases => [
            {
                description => 'did not request device',
                data => { subname => '_has_no_device' },
                success_num => 1,
            },
            {
                description => 'did not request hardware_product',
                data => { subname => '_has_no_hardware_product' },
                success_num => 1,
                error_num => 1,
            },
            {
                description => 'did not request hardware_product_profile',
                data => { subname => '_has_no_hardware_product_profile' },
                error_num => 1,
            },
            {
                description => 'device_location inflation',
                data => { subname => '_device_location_inflation', rack_unit_start => 2 },
                success_num => 2,
            },
        ],
    );

    test_validation(
        'Conch::Validation::TestConchValidationTester',
        device_location => {
            rack_unit_start => 3,
            datacenter_rack => {
                name => 'my rack',
            },
            datacenter_rack_layouts => [ { rack_unit_start => 3 } ],
        },
        cases => [
            {
                description => 'did not request device',
                data => { subname => '_has_no_device' },
                success_num => 1,
            },
            {
                description => 'did not request hardware_product',
                data => { subname => '_has_no_hardware_product' },
                success_num => 1,
                error_num => 1,
            },
            {
                description => 'did not request hardware_product_profile',
                data => { subname => '_has_no_hardware_product_profile' },
                error_num => 1,
            },
            {
                description => 'device_location inflation',
                data => { subname => '_device_location_inflation', rack_unit_start => 3 },
                success_num => 2,
            },
            {
                description => 'datacenter_rack inflation',
                data => { subname => '_datacenter_rack_inflation', rack_unit_start => 3, datacenter_rack_name => 'my rack' },
                success_num => 1,
            },
        ],
    );

    test_validation(
        'Conch::Validation::TestConchValidationTester',
        device_settings => { foo => 'bar' },
        cases => [
            {
                description => 'did not request device',
                data => { subname => '_has_no_device' },
                success_num => 1,
            },
            {
                description => 'did not request hardware_product',
                data => { subname => '_has_no_hardware_product' },
                success_num => 1,
                error_num => 1,
            },
            {
                description => 'did not request hardware_product_profile',
                data => { subname => '_has_no_hardware_product_profile' },
                error_num => 1,
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
