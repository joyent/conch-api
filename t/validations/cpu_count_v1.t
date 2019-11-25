use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::CpuCount',
    hardware_product => {
        cpu_num => 2,
    },
    cases => [
        {
            description => 'Missing cpus',
            data        => {},
        },
        {
            description => 'Incorrect processor count',
            data        => { cpus => [ { core_id => '0' } ] },
            failure_num => 1,
        },
        {
            description => 'Correct processor count',
            data        => { cpus => [ { core_id => '0' }, { core_id => '1' } ] },
            success_num => 1,
        },
    ]
);

done_testing;
