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

subtest 'failed query params validation' => sub {
    my $r = Mojolicious::Routes->new;
    $r->get('/_hello', sub ($c) {
        my $params = $c->validate_query_params('ChangePassword');
        return if not $params;
        return $c->status(200);
    });
    $t->add_routes($r);

    $t->get_ok('/_hello?clear_tokens=whargarbl')
        ->status_is(400)
        ->json_schema_is('QueryParamsValidationError')
        ->json_cmp_deeply({
            error => 'query parameters did not match required format',
            details => [ { path => '/clear_tokens', message => re(qr/Not in enum list/) } ],
            schema => '/schema/query_params/change_password',
            data => { clear_tokens => 'whargarbl' },
        })
        ->log_warn_like(qr{^FAILED query_params validation for schema ChangePassword: /clear_tokens: Not in enum list});
};

subtest 'failed request validation' => sub {
    $t->post_ok('/login', json => { email => 'foo@bar.com' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply({
            error => 'request did not match required format',
            details => [ { path => '/password', message => re(qr/missing property/i) } ],
            schema => '/schema/request/login',
        })
        ->log_warn_like(qr{^FAILED request payload validation for schema Login: /password: Missing property});
};

subtest '/device/:id/interface/:iface_name/:field validation' => sub {
    my $validator = $t->app->get_response_validator;
    my $schema = $validator->get('/definitions/DeviceNicField');

    cmp_deeply(
        [ $validator->validate({ device_id => create_uuid_str() }, $schema) ],
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
            rack_role_name => 'some role',
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
        [
            methods(
                path => '/some_room_name/0/device_progress',
                message => re(qr/Does not match const/),
            ),
            methods(
                path => '/some_room_name/0/device_progress',
                message => re(qr/Not in enum list/),
            ),
        ],
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

subtest 'device report validation' => sub {
    my $validator = JSON::Validator->new
        ->load_and_validate_schema('json-schema/device_report.yaml',
            { schema => 'http://json-schema.org/draft-07/schema#' });

    cmp_deeply(
        [ $validator->validate('00000000-0000-0000-0000-000000000000',
                $validator->get('/definitions/DeviceReport_v3.0.0/properties/system_uuid')) ],
        [ methods(
            path => '/',
            message => re(qr/should not match/i),
        ) ],
        'all-zero system_uuids are rejected',
    );

    cmp_deeply(
        [ $validator->validate({ '' => {} },
                $validator->get('/definitions/DeviceReport_v3.0.0/properties/disks')) ],
        [ methods(
            path => '/',
            message => re(qr{/propertyName/ String does not match '?\^\\S\+\$'?}i),
        ) ],
        'bad disk entries are rejected',
    );
};

done_testing;
