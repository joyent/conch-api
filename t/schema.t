use strict;
use warnings;

use Test::Conch;
use Test::More;
use Test::Warnings;
use JSON::Validator;
use Mojo::JSON 'decode_json';
use Mojo::File 'path';
use Test::Deep;
use Test::Fatal;
use Conch::Controller::Schema;

my $_validator = JSON::Validator->new;
$_validator->schema('http://json-schema.org/draft-07/schema#');

subtest 'extraction with $refs' => sub {
    # these are tuples: expected result from extracting title name, and test name.
    my @tests = (
        [
            {
                title => 'i_have_nested_refs',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_have_nested_refs.schema.json',
                # begin all referenced definitions
                definitions => {
                    ref1 => {
                        type => 'array',
                        items => {
                            '$ref' => '/definitions/ref2',
                        },
                    },
                    ref2 => {
                        type => 'string',
                        minLength => 1,
                    },
                },
                # begin i_have_nested_refs definition
                type => 'object',
                properties => {
                    my_key1 => {
                        '$ref' => '/definitions/ref1',
                    },
                    my_key2 => {
                        '$ref' => '/definitions/ref1',
                    },
                },
            },
            'find and resolve nested $refs; main schema is at the top level',
        ],

        [
            {
                title => 'i_have_a_recursive_ref',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_have_a_recursive_ref.schema.json',
                # begin all referenced definitions
                definitions => {
                    i_have_a_recursive_ref => {
                        type => 'object',
                        properties => {
                            name => { type => 'string' },
                            children => {
                                type => 'array',
                                items => { '$ref' => '/definitions/i_have_a_recursive_ref' },
                                default => [],
                            },
                        },
                    },
                },
                # begin i_have_a_recursive_ref definition
                # it is duplicated with the above, but there is no other way,
                # because $ref cannot be combined with other sibling keys
                type => 'object',
                properties => {
                    name => { type => 'string' },
                    children => {
                        type => 'array',
                        items => { '$ref' => '/definitions/i_have_a_recursive_ref' },
                        default => [],
                    },
                },
            },
            'find and resolve recursive $refs',
        ],

        [
            {
                title => 'i_have_a_ref_to_another_file',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_have_a_ref_to_another_file.schema.json',
                # begin all referenced definitions
                definitions => {
                    my_name => {
                        type => 'string',
                        minLength => 2,
                    },
                    my_address => {
                        type => 'object',
                        properties => {
                            street => {
                                type => 'string',
                            },
                            city => {
                                '$ref' => '/definitions/my_name',
                            },
                        },
                    },
                    ref1 => {
                        type => 'array',
                        items => {
                            '$ref' => '/definitions/ref2',
                        },
                    },
                    ref2 => {
                        type => 'string',
                        minLength => 1,
                    },
                },
                # begin i_have_a_ref_to_another_file definition
                type => 'object',
                properties => {
                    # these ref targets are rewritten
                    name => { '$ref' => '/definitions/my_name' },
                    address => { '$ref' => '/definitions/my_address' },
                    secrets => { '$ref' => '/definitions/ref1' },
                },
            },
            'find and resolve references to other local files',
        ],

        [
            {
                title => 'i_am_a_ref',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_am_a_ref.schema.json',
                # begin all referenced definitions
                definitions => {
                    ref2 => {
                        type => 'string',
                        minLength => 1,
                    },
                },
                # begin i_am_a_ref definition - which is actually ref1
                type => 'array',
                items => {
                    '$ref' => '/definitions/ref2',
                },
            },
            'find and resolve references where the definition itself is a ref',
        ],

        [
            {
                title => 'i_am_a_ref_level_1',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_am_a_ref_level_1.schema.json',
                # begin i_am_a_ref definition - which is actually (eventually) ref3
                type => 'integer',
            },
            'find and resolve references where the definition itself is a ref, multiple times over',
        ],

        [
            {
                title => 'i_have_refs_with_the_same_name',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_have_refs_with_the_same_name.schema.json',
                # begin all referenced definitions
                definitions => {
                    i_am_a_ref_with_the_same_name => {
                        type => 'string',
                    },
                },
                # begin i_have_a_ref_with_the_same_name definition
                type => 'object',
                properties => {
                    me => {
                        '$ref' => '/definitions/i_am_a_ref_with_the_same_name',
                    },
                },
            },
            '$refs which are simply $refs themselves are traversed automatically during resolution',
        ],

        [
            {
                title => 'i_am_a_ref_with_the_same_name',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_am_a_ref_with_the_same_name.schema.json',
                # begin i_am_a_ref_with_the_same_name definition - pulled from secondary file
                type => 'string',
            },
            '$refs which are simply $refs themselves are traversed automatically during resolution, at the top level too',
        ],

        [
            {
                title => 'i_contain_refs_to_same_named_definitions',
                exception => qr!namespace collision: .*t/data/test-schema2?\.yaml#/definitions/dupe_name but already have a /definitions/dupe_name from .*t/data/test-schema2?\.yaml#/definitions/dupe_name!,
            },
            'cannot handle pulling in references that have the same root name',
        ],

        [
            {
                title => 'i_have_a_ref_with_the_same_name',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_have_a_ref_with_the_same_name.schema.json',
                # begin all referenced definitions
                definitions => {
                    i_have_a_ref_with_the_same_name => { type => 'string' },
                },
                # begin i_have_a_ref_with_the_same_name definition
                type => 'object',
                properties => {
                    name => { type => 'string' },
                    children => {
                        type => 'array',
                        items => { '$ref' => '/definitions/i_have_a_ref_with_the_same_name' },
                        default => [],
                    },
                },
            },
            'we can handle pulling in references that have the same root name as the top level name',
        ],

        [
            {
                title => 'i_am_a_ref_to_another_file',
                '$schema' => 'http://json-schema.org/draft-07/schema#',
                '$id' => 'urn:i_am_a_ref_to_another_file.schema.json',
                # begin all referenced definitions
                definitions => {
                    ref3 => { type => 'integer' },
                },
                # begin i_am_a_ref_to_another_file definition - which is actually i_have_a_ref_to_the_first_filename
                type => 'object',
                properties => {
                    gotcha => { '$ref' => '/definitions/ref3' },
                },
            },
            'find and resolve a reference that immediately leaps to another file',
        ],

    );

    my $jv = JSON::Validator->new;
    $jv->load_and_validate_schema('t/data/test-schema.yaml', { schema => 'http://json-schema.org/draft-07/schema#' });

    subtest $_->[1] => sub {
        my ($expected_output, $test_name) = $_->@*;

        my $title = $expected_output->{title};
        my $got;
        my $exception = exception {
            $got = Conch::Controller::Schema::_extract_schema_definition($jv, $title);
        };

        if (my $message = $expected_output->{exception}) {
            like($exception, $message, 'died trying to extract schema for '.$title)
                or note('lived, and got: ', explain($got));
            return;
        }

        is($exception, undef, 'no exceptions extracting schema for '.$title)
            or return;
        cmp_deeply($got, $expected_output, 'extracted schema for '.$title);

        my @errors = $_validator->validate($got);
        ok(!@errors, 'no validation errors in the generated schema');

        my $_jv = JSON::Validator->new;
        $_jv->load_and_validate_schema($got, { schema => 'http://json-schema.org/draft-07/schema#' });
        cmp_deeply(
            $_jv->schema->data,
            $expected_output,
            'our generated schema does not lose any data when parsed again by a validator',
        );
    }
    foreach @tests;
};


my $t = Test::Conch->new(pg => undef);
my $json_spec_schema = $_validator->schema->data;

$t->get_ok('/schema/REQUEST/hello')
    ->status_is(404)
    ->json_is({ error => 'Route Not Found' })
    ->log_error_is('no endpoint found for: GET /schema/REQUEST/hello');

$t->get_ok('/schema/request/hello')
    ->status_is(404)
    ->log_debug_is('Could not find request schema Hello');

$t->get_ok('/schema/response/Ping' => { 'If-Modified-Since' => 'Sun, 01 Jan 2040 00:00:00 GMT' })
    ->header_is('Last-Modified', $t->app->startup_time->strftime('%a, %d %b %Y %T GMT'))
    ->status_is(304);

$t->get_ok('/schema/response/Ping' => { 'If-Modified-Since' => 'Sun, 01 Jan 2006 00:00:00 GMT' })
    ->header_is('Last-Modified', $t->app->startup_time->strftime('%a, %d %b %Y %T GMT'))
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_cmp_deeply({
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        '$id' => 'urn:response.Ping.schema.json',
        title => 'Ping',
        type => 'object',
        additionalProperties => bool(0),
        required => ['status'],
        properties => { status => { const => 'ok' } },
    });

$t->get_ok('/schema/response/LoginToken')
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_cmp_deeply({
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        '$id' => 'urn:response.LoginToken.schema.json',
        title => 'LoginToken',
        type => 'object',
        additionalProperties => bool(0),
        required => ['jwt_token'],
        properties => { jwt_token => { type => 'string', pattern => '[^.]+\.[^.]+\.[^.]+' } },
    });

$t->get_ok('/schema/request/Login')
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_cmp_deeply({
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        '$id' => 'urn:request.Login.schema.json',
        title => 'Login',
        type => 'object',
        additionalProperties => bool(0),
        required => [ 'password' ],
        oneOf => [ { required => [ 'user_id' ] }, { required => [ 'email' ] } ],
        properties => {
            user_id => { '$ref' => '/definitions/uuid' },
            email => { '$ref' => '/definitions/email_address' },
            password => { '$ref' => '/definitions/non_empty_string' },
            set_session => { type => 'boolean', default => JSON::PP::false },
        },
        definitions => {
            non_empty_string => { type => 'string', minLength => 1 },
            uuid => superhashof({}),
            email_address => superhashof({}),
            mojo_relaxed_placeholder => superhashof({}),
        },
    });

$t->get_ok('/schema/query_params/workspace_relays')
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_cmp_deeply({
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        '$id' => 'urn:query_params.WorkspaceRelays.schema.json',
        title => 'WorkspaceRelays',
        definitions => {
            non_negative_integer => { type => 'integer', minimum => 0 },
        },
        type => 'object',
        additionalProperties => bool(0),
        properties => {
            active_minutes => { '$ref' => '/definitions/non_negative_integer' },
        },
    });

$t->get_ok('/schema/request/HardwareProductCreate')
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_cmp_deeply('', superhashof({
        definitions => {
            map +($_ => superhashof({})), qw(
                uuid
                positive_integer
                non_empty_string
                mojo_standard_placeholder
                HardwareProductUpdate
            )
        },
    }), 'nested definitions are found and included');

$t->get_ok('/schema/request/device_report')
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_is('/$schema', 'http://json-schema.org/draft-07/schema#');

# ensure that one of the schemas can validate some data
{
    my $report = decode_json(path('t/integration/resource/passing-device-report.json')->slurp);
    my $schema = $t->get_ok('/schema/request/device_report')->tx->res->json;

    # FIXME: JSON::Validator should be picking this up out of the schema on its own.
    my $jv = JSON::Validator->new;
    $jv->load_and_validate_schema($schema, { schema => $schema->{'$schema'} });
    is($jv->version, 7, 'schema declares JSON Schema version 7');
    my @errors = $jv->validate($report);
    is(scalar @errors, 0, 'no errors');
}

$t->get_ok('/schema/request/device_report')
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_is('/$schema', 'http://json-schema.org/draft-07/schema#');

# ensure that one of the schemas can validate some data
{
    my $report = decode_json(path('t/integration/resource/passing-device-report.json')->slurp);
    my $schema = $t->get_ok('/schema/request/device_report')->tx->res->json;
    my $jv = JSON::Validator->new;
    $jv->load_and_validate_schema($schema);
    my @errors = $jv->validate($report);
    is(scalar @errors, 0, 'no errors');
}

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
