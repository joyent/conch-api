use strict;
use warnings;
use warnings FATAL => 'utf8';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use experimental 'signatures';

use Test::More;
use Test::Warnings;
use Test::Conch;
use Test::Deep;
use Conch::Validation;
require Devel::Confess;

use lib 't/lib';

my $t = Test::Conch->new;

my $device = $t->load_fixture('device_HAL');
$device = $t->app->db_ro_devices->find($device->id);

subtest '->run, local exception' => sub {
    $t->reset_log;

    require Conch::Validation::LocalException;
    my $validator = Conch::Validation::LocalException->new(
        log              => $t->app->log,
        device           => $device,
    );
    $validator->run({});

    cmp_deeply(
        [ $validator->validation_results ],
        [
            {
                name => 'local_exception',
                status => 'error',
                message => 'I did something dumb',
                category => 'exception',
                hint => 't/lib/Conch/Validation/LocalException.pm line 11',
            },
        ],
        'correctly parsed an exception from an external library containing a stack trace',
    );

    $t->log_error_is(
        re(qr/Validation 'local_exception' threw an exception on device id '${\$device->id}': I did something dumb/),
        'logged the unexpected exception',
    );
};

my $exception_test = sub ($use_stack_traces = 0) {
    $use_stack_traces
        ? Devel::Confess->import
        : Devel::Confess->unimport;

    $t->reset_log;

    require Conch::Validation::ExternalException;
    my $validator = Conch::Validation::ExternalException->new(
        log              => $t->app->log,
        device           => $device,
    );
    $validator->run({});

    cmp_deeply(
        [ $validator->validation_results ],
        [
            {
                name => 'external exception',
                status => 'error',
                message => re(qr/unexpected end of string while parsing JSON string/),
                category => 'exception',
                hint => 't/lib/Conch/Validation/ExternalException.pm line 12',
            },
        ],
        'correctly parsed an exception from an external library, identifying the validator line that called the library',
    );

    $t->log_error_is(
        re(qr/unexpected end of string while parsing JSON string/),
        'logged the unexpected exception',
    );
};

subtest '->run, unblessed external exception with no stack trace' => $exception_test, 0;

subtest '->run, unblessed external exception with stack trace' => $exception_test, 1;

subtest '->run, blessed external exception containing a stack trace' => sub {
    $t->reset_log;

    require Conch::Validation::MutateDevice;
    my $validator = Conch::Validation::MutateDevice->new(
        log              => $t->app->log,
        device           => $device,
    );
    $validator->run({});

    cmp_deeply(
        [ $validator->validation_results ],
        [
            {
                name => 'mutate_device',
                status => 'error',
                message => re(qr/permission denied for relation device/),
                category => 'exception',
                hint => 't/lib/Conch/Validation/MutateDevice.pm line 17',
            },
        ],
        'correctly parsed an exception from an external library containing a stack trace',
    );

    $t->log_error_is(
        re(qr/Validation 'mutate_device' threw an exception on device id '${\$device->id}': .*permission denied for relation device/),
        'logged the unexpected exception',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
