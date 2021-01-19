use strict;
use warnings;
use experimental 'signatures';

use Test::Conch;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Fatal;
use Conch::UUID 'create_uuid_str';
use Path::Tiny;

my $t = Test::Conch->new(pg => undef);
my $base_uri = $t->ua->server->url; # used as the base uri for all requests

subtest 'failed query params validation' => sub {
    my $r = Mojolicious::Routes->new;
    $r->get('/_hello', { query_params_schema => 'Anything' },
        sub ($c) {
            return if not $c->validate_query_params('ChangePassword');
            return $c->status(200);
        });
    $t->add_routes($r);

    $t->get_ok('/_hello?clear_tokens=whargarbl')
        ->status_is(400)
        ->json_schema_is('QueryParamsValidationError')
        ->json_cmp_deeply({
            error => 'query parameters did not match required format',
            details => [
                {
                    data_location => '/clear_tokens',
                    schema_location => '/properties/clear_tokens/enum',
                    absolute_schema_location => $base_uri.'json_schema/query_params/ChangePassword#/properties/clear_tokens/enum',
                    error => 'value does not match',
                },
            ],
            schema => $base_uri.'json_schema/query_params/ChangePassword',
            data => { clear_tokens => 'whargarbl' },
        })
        ->log_warn_like(qr{^FAILED query_params validation for schema ChangePassword: .*value does not match});
};

subtest 'insert defaults for missing query parameter values' => sub {
    my $validator = $t->app->json_schema_validator;
    my $data = {};
    my $result = $validator->evaluate($data, 'query_params.yaml#/$defs/RevokeUserTokens');
    ok($result, 'got no validation errors');
    cmp_deeply($data, {}, 'no default coercion from the validator itself');

    ok($t->app->validate_query_params('RevokeUserTokens', $data), 'no validation errors here either');
    cmp_deeply(
        $data,
        {
            login_only => 0,
            api_only => 0,
            send_mail => 1,
        },
        'empty params hash populated with default values',
    );
};

subtest 'failed request validation' => sub {
    $t->post_ok('/login', json => { email => 'foo@bar.com' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply({
            error => 'request did not match required format',
            details => [
                {
                    data_location => '',
                    schema_location => '/required',
                    absolute_schema_location => $base_uri.'json_schema/request/Login#/required',
                    error => 'missing property: password',
                },
            ],
            schema => $base_uri.'json_schema/request/Login',
        })
        ->log_warn_like(qr{^FAILED request payload validation for schema Login: .*missing property});
};

subtest '/device/:id/interface/:iface_name/:field validation' => sub {
    my $validator = $t->app->json_schema_validator;
    my $schema = 'response.yaml#/$defs/DeviceNicField';

    cmp_deeply(
        $validator->evaluate({ device_id => create_uuid_str() }, $schema)->TO_JSON,
        {
            valid => JSON::PP::false,
            errors => [
                {
                    instanceLocation => '/device_id',
                    keywordLocation => '/properties/device_id',
                    absoluteKeywordLocation => 'response.yaml#/$defs/DeviceNicField/properties/device_id',
                    error => 'property not permitted',
                },
            ],
        },
        'device_id is not a valid response field',
    );

    cmp_deeply(
        $validator->evaluate({ created => '2018-01-02T00:00:00.000+00:20' }, $schema)->TO_JSON,
        {
            valid => JSON::PP::false,
            errors => [
                {
                    instanceLocation => '/created',
                    keywordLocation => '/$ref/additionalProperties',
                    absoluteKeywordLocation => 'response.yaml#/$defs/DeviceNicFields/additionalProperties',
                    error => 'additional property not permitted',
                },
            ],
        },
        'created is not a valid response field',
    );

    ok(
        $validator->evaluate({ iface_name => 'foo' }, $schema),
        'iface_name is a valid response field',
    );
};

subtest 'device report validation' => sub {
    my $validator = $t->app->json_schema_validator;

    cmp_deeply(
        $validator->evaluate('00000000-0000-0000-0000-000000000000',
            'device_report.yaml#/$defs/DeviceReport_v3_2_0/properties/system_uuid')->TO_JSON,
        {
            valid => JSON::PP::false,
            errors => [
                {
                    instanceLocation => '',
                    keywordLocation => '/$ref/not',
                    absoluteKeywordLocation => 'common.yaml#/$defs/non_zero_uuid/not',
                    error => 'subschema is valid',
                },
            ],
        },
        'all-zero system_uuids are rejected',
    );

    cmp_deeply(
        $validator->evaluate({ '' => {} },
            'device_report.yaml#/$defs/DeviceReport_v3_2_0/properties/disks')->TO_JSON,
        {
            valid => JSON::PP::false,
            errors => [
                {
                    instanceLocation => '/',
                    keywordLocation => '/propertyNames/$ref/pattern',
                    absoluteKeywordLocation => 'common.yaml#/$defs/disk_serial_number/pattern',
                    error => 'pattern does not match',
                },
            ],
        },
        'bad disk entries are rejected',
    );
};

subtest 'result normalization' => sub {
  my $c = $t->app->build_controller;
  $c->tx->req->url(Mojo::URL->new('/foo/bar/baz')->base(Mojo::URL->new('https://localhost:1234')));

  my $js = JSON::Schema::Draft201909->new(output_format => 'terse');
  $js->add_schema('common.yaml' => {
    '$defs' => {
      False => JSON::PP::false,
      NoProps => { additionalProperties => JSON::PP::false },
    },
  });

  cmp_deeply(
    [ $c->normalize_evaluation_result($js->evaluate('foo', { '$ref' => 'common.yaml#/$defs/False' })) ],
    [ {
      data_location => '',
      schema_location => '/$ref',
      absolute_schema_location => 'https://localhost:1234/json_schema/common/False',
      error => 'subschema is false',
    } ],
    'correctly normalized the JSON evaluation result, erroring at the top of the definition ',
  );

  cmp_deeply(
    [ $c->normalize_evaluation_result($js->evaluate({ hi => 1 }, { '$ref' => 'common.yaml#/$defs/NoProps' })) ],
    [ {
      data_location => '/hi',
      schema_location => '/$ref/additionalProperties',
      absolute_schema_location => 'https://localhost:1234/json_schema/common/NoProps#/additionalProperties',
      error => 'additional property not permitted',
    } ],
    'correctly normalized the JSON evaluation result, erroring inside the definition',
  );
};

subtest '*Error response schemas' => sub {
    my $validator = $t->app->json_schema_validator;
    my $defs = $validator->get('response.yaml#/$defs');

    my $schema = {
        type => 'object',
        required => [ 'type', 'required', 'properties' ],
        properties => {
            type => { const => 'object' },
            required => { contains => { const => 'error' } },
            properties => { # the literal key /properties
                type => 'object',
                required => [ 'error' ],
                properties => {
                    error => {  # the literal key /properties/error
                        type => 'object',
                        required => [ 'type' ],
                        properties => {
                            type => { const => 'string' },  # /properties/error/type
                        },
                    },
                },
            },
        },
    };

    foreach my $schema_name (sort grep /Error$/, keys $defs->%*) {
        next if $schema_name eq 'JSONSchemaError';
        my $result = $validator->evaluate($defs->{$schema_name}, $schema);
        ok($result, 'schema '.$schema_name.' is a superset of the Error schema')
            or diag 'got errors: ', explain([ map $_->TO_JSON, $result->errors ]);
    }
};

subtest 'automatic validation of query params and request payloads' => sub {
    my sub add_routes ($t) {
        my $r = Mojolicious::Routes->new;
        $r->post('/_simple_post',
            { query_params_schema => 'NotifyUsers', request_schema => 'DeviceSetting' },
            sub ($c) { $c->status(204) });

        $r->under('/_chained_post',
                { query_params_schema => 'FindDevice', request_schema => 'UserIdOrEmail' }, sub ($c) { 1 })
            ->post('/',
                { query_params_schema => 'GetValidationState', request_schema => 'BuildAddUser' },
                sub ($c) { $c->status(204) });

        $t->add_routes($r);
    }

    my $t = Test::Conch->new(pg => undef);
    my $base_uri = $t->ua->server->url; # used as the base uri for all requests

    add_routes($t);

    $t->post_ok('/_simple_post?foo=1')
        ->status_is(400)
        ->json_schema_is('QueryParamsValidationError')
        ->json_cmp_deeply({
            error => 'query parameters did not match required format',
            details => [
                superhashof({ error => 'additional property not permitted' }),
            ],
            schema => $base_uri.'json_schema/query_params/NotifyUsers',
            data => { foo => 1 },
        })
        ->log_warn_like(qr{^FAILED query_params validation for schema NotifyUsers: .*additional property not permitted})
        ->stash_cmp_deeply('/query_params', undef)
        ->stash_cmp_deeply('/request_data', undef)
        ->stash_cmp_deeply('/validated', { query_params_schema => [], request_schema => [] });

    $t->post_ok('/_simple_post?send_mail=1', json => { foo => 'bar', baz => 'quux' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply({
            error => 'request did not match required format',
            details => [ superhashof({ error => 'more than 1 property' }) ],
            schema => $base_uri.'json_schema/request/DeviceSetting',
        })
        ->log_debug_is('Passed data validation for query_params schema NotifyUsers')
        ->log_warn_like(qr{^FAILED request payload validation for schema DeviceSetting: .*more than 1 property})
        ->stash_cmp_deeply('/query_params', { send_mail => 1 })
        ->stash_cmp_deeply('/request_data', undef)
        ->stash_cmp_deeply('/validated', { query_params_schema => ['NotifyUsers'], request_schema => [] });

    $t->post_ok('/_simple_post?send_mail=0', json => { foo => 'bar' })
        ->status_is(204)
        ->log_debug_is('Passed data validation for query_params schema NotifyUsers')
        ->log_debug_is('Passed data validation for request schema DeviceSetting')
        ->stash_cmp_deeply('/query_params', { send_mail => 0 })
        ->stash_cmp_deeply('/request_data', { foo => 'bar' })
        ->stash_cmp_deeply('/validated', { query_params_schema => ['NotifyUsers'], request_schema => ['DeviceSetting'] });


    $t->post_ok('/_chained_post?phase_earlier_than=foo')
        ->status_is(400)
        ->json_schema_is('QueryParamsValidationError')
        ->json_cmp_deeply({
            error => 'query parameters did not match required format',
            details => [
                superhashof({ schema_location => '/properties/phase_earlier_than/oneOf/0/const', error => 'value does not match' }),
                superhashof({ schema_location => '/properties/phase_earlier_than/oneOf/1/$ref/enum', error => 'value does not match' }),
            ],
            schema => $base_uri.'json_schema/query_params/FindDevice',
            data => { phase_earlier_than => 'foo' },
        })
        ->log_warn_like(qr{^FAILED query_params validation for schema FindDevice: .*value does not match})
        ->stash_cmp_deeply('/query_params', undef)
        ->stash_cmp_deeply('/request_data', undef)
        ->stash_cmp_deeply('/validated', { query_params_schema => [], request_schema => [] });

    $t->post_ok('/_chained_post?phase_earlier_than=production', json => { email => 'foo' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply({
            error => 'request did not match required format',
            details => [ superhashof({ error => 'not an email' }) ],
            schema => $base_uri.'json_schema/request/UserIdOrEmail',
        })
        ->log_debug_is('Passed data validation for query_params schema FindDevice')
        ->log_warn_like(qr{^FAILED request payload validation for schema UserIdOrEmail: .*/email.*not an email})
        ->stash_cmp_deeply('/query_params', { phase_earlier_than => 'production' })
        ->stash_cmp_deeply('/request_data', undef)
        ->stash_cmp_deeply('/validated', { query_params_schema => ['FindDevice'], request_schema => [] });

    $t->post_ok('/_chained_post?phase_earlier_than=production&status=foo', json => { email => 'foo@bar.com' })
        ->status_is(400)
        ->json_schema_is('QueryParamsValidationError')
        ->json_cmp_deeply({
            error => 'query parameters did not match required format',
            details => superbagof(
                superhashof({
                    absolute_schema_location => $base_uri.'json_schema/common/validation_status#/enum',
                    error => 'value does not match',
                }),
            ),
            schema => $base_uri.'json_schema/query_params/GetValidationState',
            data => { phase_earlier_than => 'production', status => 'foo' },
        })
        ->log_debug_is('Passed data validation for query_params schema FindDevice')
        ->log_debug_is('Passed data validation for request schema UserIdOrEmail')
        ->log_warn_like(qr{^FAILED query_params validation for schema GetValidationState: .*value does not match})
        ->stash_cmp_deeply('/query_params', { phase_earlier_than => 'production', status => 'foo' })
        ->stash_cmp_deeply('/request_data', { email => 'foo@bar.com' })
        ->stash_cmp_deeply('/validated', { query_params_schema => ['FindDevice'], request_schema => ['UserIdOrEmail'] });

    $t->post_ok('/_chained_post?phase_earlier_than=production&status=pass', json => { email => 'foo@bar.com', role => 'foo' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply({
            error => 'request did not match required format',
            details => [ superhashof({ data_location => '/role', error => 'value does not match' }) ],
            schema => $base_uri.'json_schema/request/BuildAddUser',
        })
        ->log_debug_is('Passed data validation for query_params schema FindDevice')
        ->log_debug_is('Passed data validation for request schema UserIdOrEmail')
        ->log_debug_is('Passed data validation for query_params schema GetValidationState')
        ->log_warn_like(qr{^FAILED request payload validation for schema BuildAddUser: .*/role.*value does not match})
        ->stash_cmp_deeply('/query_params', { phase_earlier_than => 'production', status => 'pass' })
        ->stash_cmp_deeply('/request_data', { email => 'foo@bar.com', role => 'foo' })

        ->stash_cmp_deeply('/validated', { query_params_schema => [qw(FindDevice GetValidationState)], request_schema => ['UserIdOrEmail'] });

    $t->post_ok('/_chained_post?phase_earlier_than=production&status=pass', json => { email => 'foo@bar.com', role => 'ro' })
        ->status_is(204)
        ->log_debug_is('Passed data validation for query_params schema FindDevice')
        ->log_debug_is('Passed data validation for request schema UserIdOrEmail')
        ->log_debug_is('Passed data validation for query_params schema GetValidationState')
        ->log_debug_is('Passed data validation for request schema BuildAddUser')
        ->stash_cmp_deeply('/query_params', { phase_earlier_than => 'production', status => 'pass' })
        ->stash_cmp_deeply('/request_data', { email => 'foo@bar.com', role => 'ro' })
        ->stash_cmp_deeply('/validated', { query_params_schema => [qw(FindDevice GetValidationState)], request_schema => [qw(UserIdOrEmail BuildAddUser)] });
};

subtest 'feature: validate_all_requests' => sub {
    my sub add_routes ($t) {
        my $r = Mojolicious::Routes->new;
        $r->post('/_simple_post', sub ($c) { $c->status(204) });
        $t->add_routes($r);
    }

    my $t = Test::Conch->new(pg => undef);
    my $base_uri = $t->ua->server->url; # used as the base uri for all requests
    add_routes($t);

    $t->post_ok('/_simple_post?foo=1')
        ->status_is(400)
        ->json_schema_is('QueryParamsValidationError')
        ->json_cmp_deeply({
            error => 'query parameters did not match required format',
            details => [ superhashof({ error => 'additional property not permitted' }) ],
            schema => $base_uri.'json_schema/query_params/Null',
            data => { foo => 1 },
        })
        ->log_warn_like(qr{^FAILED query_params validation for schema Null: .*additional property not permitted})
        ->stash_cmp_deeply('/validated', { query_params_schema => [], request_schema => [] });

    $t->post_ok('/_simple_post', json => $_)
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_is({
            error => 'request did not match required format',
            details => [{
                data_location => '',
                schema_location => '/type',
                absolute_schema_location => $base_uri.'json_schema/request/Null#/type',
                error => 'wrong type (expected null)',
            }],
            schema => $base_uri.'json_schema/request/Null',
        })
        ->log_debug_is('Passed data validation for query_params schema Null')
        ->log_warn_like(qr{^FAILED request payload validation for schema Null: .*wrong type \(expected null\)})
        ->stash_cmp_deeply('/validated', { query_params_schema => ['Null'], request_schema => [] })
    foreach
        JSON::PP::true,
        1,
        'bad payload',
        { bad => 'payload' },
        [ qw(bad payload) ],
    ;

    undef $t;
    my $t2 = Test::Conch->new(config => { features => { no_db => 1, validate_all_requests => 0 } });
    add_routes($t2);

    $t2->post_ok('/_simple_post?foo=1')
        ->status_is(204)
        ->stash_cmp_deeply('/validated', { query_params_schema => [], request_schema => [] });

    $t2->post_ok('/_simple_post', json => { foo => 'bar' })
        ->status_is(204)
        ->stash_cmp_deeply('/validated', { query_params_schema => [], request_schema => [] });
};

subtest 'feature: validate_all_responses' => sub {
    my sub add_routes ($t) {
        my $r = Mojolicious::Routes->new;
        $r->post('/_simple_post', sub ($c) {
            $c->add_link_to_schema('Foo');
            $c->status(200, { foo => 'bad response' });
        });

        $r->get('/_pass_no_schema', { response_schema => 'IDoNotExist' },
            sub ($c) { $c->status(200, { foo => 'bar' }); },
        );
        $r->get('/_fail_no_schema', { response_schema => 'IDoNotExist' },
            sub ($c) { $c->status(400, { foo => 'bar' }); },
        );

        $r->get('/_good_multi_get', { response_schema => [ qw(DeviceIds DeviceSerials) ] },
            sub ($c) { $c->stash('response_schema', 'DeviceSerials'); $c->status(200, [ qw(foo bar) ]); },
        );

        $r->get('/_bad_multi_get', { response_schema => [ qw(DeviceIds DeviceSerials) ] },
            sub ($c) {
                $c->res->headers->link('mollify status_is check');
                $c->status(200, [ 'foo', 'bar baz' ]);
            },
        );

        $r->get('/_bad_error', sub ($c) { $c->status(400, { foo => 'bad error' }) });

        $r->get('/_user_error', { response_schema => 'IDoNotExist' },
            sub ($c) {
                $c->stash('response_schema', 'UserError');
                $c->status(400, {
                    error => 'message',
                    user => {
                        id => create_uuid_str(),
                        email => 'foo@bar.com',
                        name => 'foo',
                        email => 'foo@bar.com',
                        created => Conch::Time->now,
                        deactivated => undef,
                    },
                });
            });

        $t->add_routes($r);
    }

    {
        local $ENV{SKIP_LOG_FATAL_TEST} = 1;
        my $t = Test::Conch->new(pg => undef);
        my $base_uri = $t->ua->server->url; # used as the base uri for all requests
        add_routes($t);

        $t->get_ok('/ping')
            ->status_is(200)
            ->header_is('Link', '</json_schema/response/Ping>; rel="describedby"')
            ->json_schema_is('Ping')
            ->json_is({ status => 'ok' })
            ->stash_cmp_deeply('/response_validation_errors', { Ping => [] })
            ->log_debug_is('Passed data validation for response schema Ping');

        $t->post_ok('/_simple_post')
            ->status_is(200)
            ->json_is({ foo => 'bad response' })
            ->log_fatal_like(qr{^FAILED response payload validation for schema Null: .*wrong type \(expected null\)})
            ->stash_cmp_deeply('/response_validation_errors', {
                Null => [ {
                    data_location => '',
                    schema_location => '/type',
                    absolute_schema_location => $base_uri.'json_schema/response/Null#/type',
                    error => 'wrong type (expected null)',
                } ],
            });

        $t->get_ok('/_pass_no_schema')
            ->status_is(200)
            ->json_is({ foo => 'bar' })
            ->log_fatal_is('unable to find resource response.yaml#/$defs/IDoNotExist')
            ->stash_cmp_deeply('/response_validation_errors', {
                IDoNotExist => [ {
                    data_location => '',
                    schema_location => '',
                    error => 'EXCEPTION: unable to find resource response.yaml#/$defs/IDoNotExist',
                } ],
            });

        $t->get_ok('/_fail_no_schema')
            ->status_is(400)
            ->json_schema_is({ not => { '$ref' => 'response.yaml#/$defs/Error' } })
            ->json_is({ foo => 'bar' })
            ->stash_cmp_deeply('/response_validation_errors', {
                Error => [
                    {
                        data_location => '',
                        schema_location => '/required',
                        absolute_schema_location => $base_uri.'json_schema/response/Error#/required',
                        error => 'missing property: error',
                    },
                    {
                        data_location => '/foo',
                        schema_location => '/additionalProperties',
                        absolute_schema_location => $base_uri.'json_schema/response/Error#/additionalProperties',
                        error => 'additional property not permitted',
                    },
                ],
            });

        $t->get_ok('/_good_multi_get')
            ->status_is(200)
            ->header_is('Link', '</json_schema/response/DeviceSerials>; rel="describedby"')
            ->json_schema_is('DeviceSerials')
            ->json_is([ 'foo', 'bar' ])
            ->log_debug_is('Passed data validation for response schema DeviceSerials')
            ->stash_cmp_deeply('/response_validation_errors', { DeviceSerials => [] });

        $t->get_ok('/_bad_multi_get')
            ->status_is(200)
            ->json_is([ 'foo', 'bar baz' ])
            ->log_fatal_is('failed to specify exact response_schema used')
            ->log_fatal_like(qr{^FAILED response payload validation for schema anyOf: \Q[DeviceIds,DeviceSerials]:\E .*pattern does not match})
            ->stash_cmp_deeply('/response_validation_errors', undef);

        $t->get_ok('/_bad_error')
            ->status_is(400)
            ->json_is({ foo => 'bad error' })
            ->log_fatal_like(qr{FAILED response payload validation for schema Error: .*missing property: error.*additional property not permitted})
            ->stash_cmp_deeply('/response_validation_errors', {
                Error => [
                    superhashof({ error => 'missing property: error' }),
                    superhashof({ error => 'additional property not permitted' }),
                ],
            });

        $t->get_ok('/_user_error')
            ->status_is(400)
            ->json_schema_is('UserError')
            ->json_cmp_deeply({ error => 'message', user => superhashof({}) })
            ->log_debug_is('Passed data validation for response schema UserError')
            ->stash_cmp_deeply('/response_validation_errors', { UserError => [] });

        undef $t;
    }


    my $t2 = Test::Conch->new(config => { features => { no_db => 1, validate_all_responses => 0 } });
    add_routes($t2);
    undef $base_uri;

    $t2->get_ok('/ping')
        ->status_is(200)
        ->json_schema_is('Ping')
        ->json_is({ status => 'ok' })
        ->stash_cmp_deeply('/response_validation_errors', undef);

    $t2->get_ok('/_pass_no_schema')
        ->status_is(200)
        ->json_is({ foo => 'bar' })
        ->stash_cmp_deeply('/response_validation_errors', undef);

    $t2->get_ok('/_fail_no_schema')
        ->status_is(400)
        ->json_schema_is({ not => { '$ref' => 'response.yaml#/$defs/Error' } })
        ->json_is({ foo => 'bar' })
        ->stash_cmp_deeply('/response_validation_errors', undef);

    $t2->post_ok('/_simple_post')
        ->status_is(200)
        ->json_is({ foo => 'bad response' })
        ->stash_cmp_deeply('/response_validation_errors', undef);

    $t2->get_ok('/_bad_error')
        ->status_is(400)
        ->json_is({ foo => 'bad error' })
        ->stash_cmp_deeply('/response_validation_errors', undef);

    $t2->get_ok('/_user_error')
        ->status_is(400)
        ->json_schema_is('UserError')
        ->json_cmp_deeply({ error => 'message', user => superhashof({}) })
        ->stash_cmp_deeply('/response_validation_errors', undef);
};

done_testing;
