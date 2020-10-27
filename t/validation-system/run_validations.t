use v5.26;
use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Conch;
use Test::Deep;
use Test::Fatal;
use Mojo::JSON 'to_json';
use Conch::LegacyValidationSystem;

use lib 't/lib';

my $t = Test::Conch->new;

my $device = $t->load_fixture('device_HAL');
$device = $t->app->db_ro_devices->find($device->id);

my ($validation_plan) = $t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName', 'Conch::Validation::BiosFirmwareVersion' ],
}]);
my $validation_product = $t->load_validation('Conch::Validation::DeviceProductName');
my $validation_bios = $t->load_validation('Conch::Validation::BiosFirmwareVersion');

my $device_report = $t->app->db_device_reports->create({
    device_id => $device->id,
    report => to_json({
        product_name => $device->hardware_product->generation_name,
        bios_version => $device->hardware_product->bios_firmware,
        sku => $device->hardware_product->sku,
    }),
});

subtest 'run_validation_plan, missing arguments' => sub {
    my $validation_system = Conch::LegacyValidationSystem->new(
        log => $t->app->log,
        schema => $t->app->ro_schema,
    );

    like(
        exception {
            $validation_system->run_validation_plan(
                validation_plan => $validation_plan,
                device => $device,
                no_save_db => 1,
            );
        },
        qr/missing data or device report/,
        'for no_save_db => 1, need either raw data or device report',
    );

    like(
        exception {
            $validation_system->run_validation_plan(
                validation_plan => $validation_plan,
                device => $device,
                data => { },
                no_save_db => 0,
            );
        },
        qr/missing device report/,
        'for no_save_db => 0, device report is mandatory',
    );
};

subtest 'run_validation_plan, without saving state' => sub {
    my $validation_system = Conch::LegacyValidationSystem->new(
        log => $t->app->log,
        schema => $t->app->ro_schema,
    );

    my ($status, @validation_results) = $validation_system->run_validation_plan(
        validation_plan => $validation_plan,
        device => $device,
        device_report => $device_report,
        no_save_db => 1,
    );

    is($status, 'pass', 'calculated the overall result from the plan');

    cmp_deeply(
        \@validation_results,
        all(
            array_each(
                methods(
                    [ isa => 'Conch::DB::Result::LegacyValidationResult' ] => bool(1),
                    in_storage => bool(0),
                    id => undef,
                    device_id => $device->id,
                    status => 'pass',
                ),
            ),
            bag(
                methods(category => 'IDENTITY', legacy_validation_id => $validation_product->id),
                methods(category => 'IDENTITY', legacy_validation_id => $validation_product->id),
                methods(category => 'BIOS', legacy_validation_id => $validation_bios->id),
            ),
        ),
        'validation results are correct',
    );
};

subtest 'run_validation_plan, with saving state' => sub {
    my $validation_system = Conch::LegacyValidationSystem->new(
        log => $t->app->log,
        schema => $t->app->rw_schema,
    );

    my $validation_state = $validation_system->run_validation_plan(
        validation_plan => $validation_plan,
        device => $device,
        device_report => $device_report,
        # no_save_db => 0, this is the default
    );

    cmp_deeply(
        $validation_state,
        all(
            methods(
                [ isa => 'Conch::DB::Result::ValidationState' ] => bool(1),
                in_storage => bool(1),
                hardware_product_id => $device->hardware_product_id,
                status => 'pass',
                device_report_id => $device_report->id,
            ),
            listmethods(
                legacy_validation_results => all(
                    array_each(
                        methods(
                            [ isa => 'Conch::DB::Result::LegacyValidationResult' ] => bool(1),
                            in_storage => bool(1),
                            device_id => $device->id,
                            status => 'pass',
                        ),
                    ),
                    bag(
                        methods(category => 'IDENTITY', legacy_validation_id => $validation_product->id),
                        methods(category => 'IDENTITY', legacy_validation_id => $validation_product->id),
                        methods(category => 'BIOS', legacy_validation_id => $validation_bios->id),
                    ),
                ),
            ),
        ),
        'validation state and results are correct',
    );
};

subtest run_validation => sub {
    my $validation_system = Conch::LegacyValidationSystem->new(
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
                    [ isa => 'Conch::DB::Result::LegacyValidationResult' ] => bool(1),
                    in_storage => bool(0),
                    id => undef,
                    device_id => $device->id,
                    legacy_validation_id => $validation_multi->id,
                ),
            ),
            [
                methods(
                    status => 'pass',
                    message => "Expected eq 'hi'. Got 'hi'.",
                    category => 'multi',
                    component => 'x',
                    hint => undef,
                ),
                methods(
                    status => 'fail',
                    message => 'new message',   # override
                    category => 'new category', # override
                    component => 'y',
                    hint => 'stfu',
                ),
            ],
        ),
        'validation results are correct',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
