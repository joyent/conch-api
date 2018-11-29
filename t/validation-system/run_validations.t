use v5.26;
use strict;
use warnings;
use Test::More;
use Test::Conch;
use Test::Deep;
use Conch::ValidationSystem;

use lib 't/lib';

my $t = Test::Conch->new;
my $pg = Conch::Pg->new($t->pg); # temporary: wire up Conch::Model::* to the same db instance

my $device = $t->load_fixture('device_HAL');
my $validation = $t->load_validation('Conch::Validation::DeviceProductName');

subtest run_validation => sub {
    my $validation_system = Conch::ValidationSystem->new(
        log => $t->app->log,
        schema => $t->app->ro_schema,
    );
    my $validation_multi = $t->load_validation('Conch::Validation::MultipleResults');

    my @validation_results = $validation_system->run_validation(
        validation => $validation_multi,
        device => $device,
        data => {},
    );

    cmp_deeply(
        \@validation_results,
        all(
            array_each(
                methods(
                    [ isa => 'Conch::DB::Result::ValidationResult' ] => bool(1),
                    in_storage => bool(0),
                    id => undef,
                    device_id => $device->id,
                    hardware_product_id => $device->hardware_product_id,
                    validation_id => $validation_multi->id,
                ),
            ),
            bag(
                methods(
                    result_order => 0,
                    status => 'pass',
                    message => "Expected eq 'hi'. Got 'hi'.",
                    category => 'multi',
                    component_id => 'x',
                    hint => undef,
                ),
                methods(
                    result_order => 1,
                    status => 'fail',
                    message => 'new message',   # override
                    category => 'new category', # override
                    component_id => 'y',
                    hint => 'stfu',
                ),
            ),
        ),
        'validation results are correct',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
