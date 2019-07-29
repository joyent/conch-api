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
use Mojo::Log;
require Devel::Confess;

use lib 't/lib';

my $t = Test::Conch->new;

my $device = $t->load_fixture('device_HAL');
$device = $t->app->db_ro_devices->find($device->id);

open my $log_fh, '>', \my $fake_log or die "cannot open to scalarref: $!";
my $logger = Mojo::Log->new(handle => $log_fh);
sub reset_log { $fake_log = ''; seek $log_fh, 0, 0; }


subtest '->run, local exception' => sub {
    reset_log;

    require Conch::Validation::LocalException;
    my $validator = Conch::Validation::LocalException->new(
        log              => $logger,
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

    like(
        $fake_log,
        qr/Validation 'local_exception' threw an exception on device id 'HAL': I did something dumb/,
        'logged the unexpected exception',
    );
};

my $exception_test = sub ($use_stack_traces = 0) {
    $use_stack_traces
        ? Devel::Confess->import
        : Devel::Confess->unimport;

    reset_log;

    require Conch::Validation::ExternalException;
    my $validator = Conch::Validation::ExternalException->new(
        log              => $logger,
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

    like(
        $fake_log,
        qr/unexpected end of string while parsing JSON string/,
        'logged the unexpected exception',
    );
};

subtest '->run, unblessed external exception with no stack trace' => $exception_test, 0;

subtest '->run, unblessed external exception with stack trace' => $exception_test, 1;

subtest '->run, blessed external exception containing a stack trace' => sub {
    reset_log;

    require Conch::Validation::MutateDevice;
    my $validator = Conch::Validation::MutateDevice->new(
        log              => $logger,
        device           => $device,
    );
    $validator->run({});

    cmp_deeply(
        [ $validator->validation_results ],
        [
            {
                name => 'mutate_device',
                status => 'error',
                message => re(qr/cannot execute UPDATE in a read-only transaction/),
                category => 'exception',
                hint => 't/lib/Conch/Validation/MutateDevice.pm line 14',
            },
        ],
        'correctly parsed an exception from an external library containing a stack trace',
    );

    like(
        $fake_log,
        qr/Validation 'mutate_device' threw an exception on device id 'HAL': .*cannot execute UPDATE in a read-only transaction/,
        'logged the unexpected exception',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
