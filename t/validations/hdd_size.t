use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Mojo::JSON 'to_json';
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::HddSize',
    hardware_product => {
        name => 'Test Product',
        specification => to_json({}),
    },
    cases => [
        {
            description => 'no hardware specification for disk size',
            data => {},
            success_num => 0,
            error_num => 0,
        },
    ],
);

test_validation(
    'Conch::Validation::HddSize',
    hardware_product => {
        name => 'Test Product',
        specification => to_json({
            disk_size => {
                pinto => 32,
                gremlin => 64,
            },
        }),
    },
    cases => [
        {
            description => 'missing drive model',
            data => {
                disks => {
                    foo => {
                        vendor => 'some corp',
                    },
                },
            },
            failure_num => 1,
        },
        {
            description => 'missing size specification for this model',
            data => {
                disks => {
                    foo => {
                        vendor => 'some corp',
                        model => 'fiesta',
                    },
                },
            },
            failure_num => 1,
        },
        {
            description => 'missing block_sz in report',
            data => {
                disks => {
                    foo => {
                        vendor => 'some corp',
                        model => 'pinto',
                    },
                },
            },
            failure_num => 1,
        },
        {
            description => 'wrong size',
            data => {
                disks => {
                    foo => {
                        model => 'pinto',
                        block_sz => 64,
                    },
                },
            },
            failure_num => 1,
        },
        {
            description => 'correct size',
            data => {
                disks => {
                    foo => {
                        model => 'pinto',
                        block_sz => 32,
                    },
                },
            },
            success_num => 1,
        },
        {
            description => 'correct size, multiple drives',
            data => {
                disks => {
                    foo => {
                        model => 'pinto',
                        block_sz => 32,
                    },
                    bar => {
                        model => 'gremlin',
                        block_sz => 64,
                    },
                },
            },
            success_num => 2,
        },
    ],
);

test_validation(
    'Conch::Validation::HddSize',
    hardware_product => {
        name => 'Test Product',
        specification => to_json({
            disk_size => {
                _default => 128,
                pinto => 32,
                gremlin => 64,
            },
        }),
    },
    cases => [
        {
            description => 'missing size specification for this model - use default (fail)',
            data => {
                disks => {
                    foo => {
                        vendor => 'some corp',
                        model => 'fiesta',
                        block_sz => 64,
                    },
                },
            },
            failure_num => 1,
        },
        {
            description => 'missing size specification for this model - use default (pass)',
            data => {
                disks => {
                    foo => {
                        vendor => 'some corp',
                        model => 'fiesta',
                        block_sz => 128,
                    },
                },
            },
            success_num => 1,
        },
    ],
);

done_testing;
