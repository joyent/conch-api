use strict;
use warnings;

use Test::Conch;
use Test::More;
use Test::Warnings;
use JSON::Validator;
use Mojo::JSON qw(decode_json);
use Mojo::File qw(path);
use Test::Deep;

my $_validator = JSON::Validator->new;
$_validator->schema('http://json-schema.org/draft-07/schema#');
my $json_spec_schema = $_validator->schema->data;

my $t = Test::Conch->new;

$t->get_ok('/schema/REQUEST/hello')
    ->status_is(404)
    ->json_is({ error => 'Not Found' });

$t->get_ok('/schema/request/hello')
    ->status_is(404);

$t->get_ok('/schema/response/Login')
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_cmp_deeply(superhashof({
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        type => 'object',
        properties => { jwt_token => { type => 'string' } },
    }));

$t->get_ok('/schema/request/Login')
    ->status_is(200)
    ->json_schema_is($json_spec_schema)
    ->json_cmp_deeply(superhashof({
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        type => 'object',
        properties => {
            user => { '$ref' => '/definitions/non_empty_string' },
            password => { '$ref' => '/definitions/non_empty_string' },
        },
        definitions => {
            non_empty_string => { type => 'string', minLength => 1 },
        },
    }));


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
