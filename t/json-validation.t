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
            details => [
                {
                    data_location => '/clear_tokens',
                    schema_location => '/properties/clear_tokens/enum',
                    absolute_schema_location => $base_uri.'json_schema/query_params/ChangePassword#/properties/clear_tokens/enum',
                    error => 'value does not match',
                },
            ],
            schema => '/json_schema/query_params/ChangePassword',
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
            schema => '/json_schema/request/Login',
        })
        ->log_warn_like(qr{^FAILED request payload validation for schema Login: .*missing property});
};

subtest '/device/:id/interface/:iface_name/:field validation' => sub {
    my $validator = $t->app->json_schema_validator;
    my $schema = 'response.yaml#/$defs/DeviceNicField';

    cmp_deeply(
        $validator->evaluate({ device_id => create_uuid_str() }, $schema)->TO_JSON,
        {
            valid => bool(0),
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
            valid => bool(0),
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
            'device_report.yaml#/$defs/DeviceReport_v3_0_0/properties/system_uuid')->TO_JSON,
        {
            valid => bool(0),
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
            'device_report.yaml#/$defs/DeviceReport_v3_0_0/properties/disks')->TO_JSON,
        {
            valid => bool(0),
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

done_testing;
