use strict;
use warnings;
use experimental 'signatures';

use Test::Conch;
use Test::More;
use Test::Warnings;
use JSON::Validator;
use Test::Deep;
use Test::Fatal;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new(pg => undef);

subtest 'failed request validation' => sub {
    $t->post_ok('/login', json => { email => 'foo@bar.com' })
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

subtest 'GET /workspace/:workspace_id_or_name/rack validation' => sub {
    my $validator = $t->app->get_response_validator;
    my $schema = $validator->get('/definitions/WorkspaceRackSummary');

    my $summary = {
        some_room_name => [ {
            id => create_uuid_str(),
            name => 'some name',
            phase => 'production',
            role_name => 'some role',
            rack_size => 1,
            device_progress => {},
        } ],
    };

    cmp_deeply(
        [ $validator->validate($summary, $schema) ],
        [],
        'empty device_progress is valid',
    );

    $summary->{some_room_name}[0]{device_progress} = { VALID => 1 };
    cmp_deeply(
        [ $validator->validate($summary, $schema) ],
        [ methods(
            path => '/some_room_name/0/device_progress',
            message => re(qr/not in enum list/i),
        ) ],
        'VALID is not a valid field in device_progress',
    );

    $summary->{some_room_name}[0]{device_progress} = { valid => 'abc' };
    cmp_deeply(
        [ $validator->validate($summary, $schema) ],
        [ methods(
            path => '/some_room_name/0/device_progress/valid',
            message => re(qr/integer.*string/i),
        ) ],
        'device_progress must contain a hash to integers',
    );

    $summary->{some_room_name}[0]{device_progress} = { valid => 1 };
    cmp_deeply(
        [ $validator->validate($summary, $schema) ],
        [],
        '"valid" is an acceptable field in device_progress',
    );

    $summary->{some_room_name}[0]{device_progress} = { valid => 1, error => 2, fail => 3, unknown => 4, pass => 5 };
    cmp_deeply(
        [ $validator->validate($summary, $schema) ],
        [],
        '"valid" and all device_health fields are acceptable fields in device_progress',
    );
};

done_testing;
