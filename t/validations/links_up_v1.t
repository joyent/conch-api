use v5.20;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch::Validation 'test_validation';

test_validation(
    'Conch::Validation::LinksUp',
    device => {
        hardware_product => {
            name => 'Test Product',
        },
    },
    cases => [
        {
            description => 'No Data yields no success',
            data        => {},
        },
        {
            description => 'No interfaces yields failure',
            data        => {
                interfaces => {}
            },
            failure_num => 1,
        },
        {
            description => 'Correct num of interfaces up',
            data        => {
                interfaces => {
                    eth0 => { state => 'up' },
                    eth1 => { state => 'up' },
                    eth2 => { state => 'up' },
                    impi1 => { state => 'up' },
                }
            },
            success_num => 1,
        },
        {
            description => 'Too few interfaces up',
            data        => {
                interfaces => {
                    eth0 => { state => 'up' },
                    eth1 => { state => 'up' },
                    eth2 => { state => 'up' },
                    eth3 => { state => 'down' },
                }
            },
            failure_num => 1,
        },
        {
            description => 'Too few interfaces reported',
            data        => {
                interfaces => {
                    eth0 => { state => 'up' },
                    eth1 => { state => 'up' },
                    eth2 => { state => 'up' },
                }
            },
            failure_num => 1,
        },
        {
            description => 'Extra interfaces up ok',
            data        => {
                interfaces => {
                    eth0 => { state => 'up' },
                    eth1 => { state => 'up' },
                    eth2 => { state => 'up' },
                    eth3 => { state => 'up' },
                    eth4 => { state => 'up' },
                }
            },
            success_num => 1,
        },
        {
            description => "Don't count ipmi1",
            data        => {
                interfaces => {
                    eth0  => { state => 'up' },
                    eth1  => { state => 'up' },
                    eth2  => { state => 'up' },
                    ipmi1 => { state => 'up' },
                }
            },
            failure_num => 1,
        },
    ]
);

done_testing;
