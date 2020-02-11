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
            schema => '/json_schema/query_params/ChangePassword',
            data => { clear_tokens => 'whargarbl' },
        })
        ->log_warn_like(qr{^FAILED query_params validation for schema ChangePassword: /clear_tokens: Not in enum list});
};

subtest 'insert defaults for missing query parameter values' => sub {
    my $validator = $t->app->get_query_params_validator;
    my $schema = $validator->get('/definitions/RevokeUserTokens');
    my $data = {};

    my @errors = $validator->validate($data, $schema);
    cmp_deeply(\@errors, [], 'got no validation errors');
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
            details => [ { path => '/password', message => re(qr/missing property/i) } ],
            schema => '/json_schema/request/Login',
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

subtest 'device report validation' => sub {
    my $validator = JSON::Validator->new
        ->load_and_validate_schema('json-schema/device_report.yaml',
            { schema => 'http://json-schema.org/draft-07/schema#' });

    cmp_deeply(
        [ $validator->validate('00000000-0000-0000-0000-000000000000',
                $validator->get('/definitions/DeviceReport_v3_0_0/properties/system_uuid')) ],
        [ methods(
            path => '/',
            message => re(qr/should not match/i),
        ) ],
        'all-zero system_uuids are rejected',
    );

    cmp_deeply(
        [ $validator->validate({ '' => {} },
                $validator->get('/definitions/DeviceReport_v3_0_0/properties/disks')) ],
        [ methods(
            path => '/',
            message => re(qr{/propertyName/ String does not match '?\^\\S\+\$'?}i),
        ) ],
        'bad disk entries are rejected',
    );
};

subtest '*Error response schemas' => sub {
    my $validator = $t->validator;
    my $definitions = $t->validator->get(['definitions']);

    $validator->schema({
        anyOf => [
            {
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
                }
            },
            {
                type => 'object',
                propertyNames => { const => 'allOf' },
                properties => {
                    allOf => {  # /allOf/*
                        type => 'array',
                        # this works because $refs have been expanded in the data already
                        items => { '$ref' => '#/anyOf/0' },   # the original base schema
                    },
                },
            }
        ],
    });

    foreach my $schema_name (sort grep /Error$/, keys $definitions->%*) {
        next if $schema_name eq 'JSONValidatorError';
        my @errors = $validator->validate($definitions->{$schema_name});
        cmp_deeply(\@errors, [], 'schema '.$schema_name.' is a superset of the Error schema')
            or diag 'got errors: ', explain([ map $_->to_string, @errors ]);
    }
};

done_testing;
