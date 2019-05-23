use strict;
use warnings;
use experimental 'signatures';

use Test::Conch;
use Test::More;
use Test::Warnings;
use JSON::Validator;
use Test::Deep;
use Test::Fatal;

my $t = Test::Conch->new(pg => undef);

subtest 'failed request validation' => sub {
    $t->post_ok('/login', json => { user => 'foo@bar.com' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply({
            error => 'request did not match required format',
            details => [ { path => '/password', message => re(qr/missing property/i) } ],
            schema => '/schema/request/login',
        });
};

subtest '/device/:id/interface/:iface_name/:field validation' => sub {
    my $validator = $t->app->get_response_validator;
    my $schema = $validator->get('/definitions/DeviceNicField');

    cmp_deeply(
        [ $validator->validate({ device_id => 'TEST' }, $schema) ],
        [ methods(message => re(qr/should not match/i)) ],
        'device_id is not a valid response field',
    );

    cmp_deeply(
        [ $validator->validate({ created => '2018-01-02T00:00:00.000+00:20' }, $schema) ],
        [ methods(message => re(qr/not allowed/i)) ],
        'created is not a valid response field',
    );

    cmp_deeply(
        [ $validator->validate({ iface_name => 'foo' }, $schema) ],
        [],
        'iface_name is a valid response field',
    );
};

done_testing;
