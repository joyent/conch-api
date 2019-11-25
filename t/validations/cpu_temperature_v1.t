use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::CpuTemperature',
    hardware_product => {
        cpu_num => 2,
    },
    cases => [
        {
            description => 'No data',
            data        => {},
        },
        {
            description => 'No temperature hash',
            data        => { temp => 'foo' },
        },
        {
            description => 'Only one CPU temperature',
            data        => { temp => { cpu0 => 10 } },
        },
        {
            description => 'Only one CPU temperature',
            data        => { temp => { cpu1 => 20 } },
        },
        {
            description => 'CPU temperatures under threshodl',
            data        => { temp => { cpu0 => 10, cpu1 => 20 } },
            success_num => 2,
        },
        {
            description => 'One CPU temperature over threshold',
            data        => { temp => { cpu0 => 100, cpu1 => 20 } },
            success_num => 1,
            failure_num => 1,
        },
        {
            description => 'Both CPU temperature over threshold',
            data        => { temp => { cpu0 => 100, cpu1 => 200 } },
            failure_num => 2,
        },
    ]
);

done_testing;
