use strict;
use warnings;
use experimental 'signatures';
use Test::More;
use Test::Conch;
use Test::Deep;
use Conch::Validation;
require Devel::Confess;

use lib 't/lib';

my $t = Test::Conch->new;

my $device = $t->load_fixture('device_HAL');

open my $log_fh, '>', \my $fake_log or die "cannot open to scalarref: $!";
my $logger = Mojo::Log->new(handle => $log_fh);
sub reset_log { $fake_log = ''; seek $log_fh, 0, 0; }


subtest '->run, local exception' => sub {
    reset_log;

    require Conch::Validation::LocalException;
    my $validator = Conch::Validation::LocalException->new(
        log              => $logger,
        device           => Conch::Model::Device->new($device->get_columns),
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
        qr/Validation 'local_exception' threw an exception: I did something dumb/,
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
        device           => Conch::Model::Device->new($device->get_columns),
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

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
