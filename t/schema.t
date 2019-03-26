use strict;

use Test::Conch;
use Test::More;
use Test::Warnings;
use JSON::Validator;
use Mojo::JSON qw(decode_json);
use Mojo::File qw(path);

my $json_schema =
    JSON::Validator->new->schema('http://json-schema.org/draft-04/schema#')
    ->schema->data;

my $t = Test::Conch->new;

$t->get_ok('/schema/request/hello')
    ->status_is(404);

$t->get_ok('/schema/response/Login')
    ->status_is(200)
    ->json_schema_is($json_schema)
    ->json_is( '/type' => 'object' )
    ->json_is( '/properties/jwt_token/type' => 'string' );

$t->get_ok('/schema/request/Login')
    ->status_is(200)
    ->json_schema_is($json_schema)
    ->json_is( '/type' => 'object' )
    ->json_is( '/properties/user/$ref'     => '/definitions/non_empty_string' )
    ->json_is( '/properties/password/$ref' => '/definitions/non_empty_string' )
    ->json_cmp_deeply('/definitions/non_empty_string' => { type => 'string', minLength => 1 } );


$t->get_ok('/schema/request/device_report')
    ->status_is(200)
    ->json_schema_is($json_schema);

# ensure that one of the schemas can validate some data
{
    my $report =
        decode_json path('t/integration/resource/passing-device-report.json')
        ->slurp;
    my $schema = $t->get_ok('/schema/request/device_report')->tx->res->json;
    my $jv     = JSON::Validator->new()->load_and_validate_schema($schema);
    my @errors = $jv->validate($report);
    is scalar @errors, 0, 'no errors';
}

$t->get_ok('/schema/request/device_report')
    ->status_is(200)
    ->json_schema_is($json_schema);

# ensure that one of the schemas can validate some data
{
    my $report = decode_json path('t/integration/resource/passing-device-report.json')->slurp;
    my $schema = $t->get_ok('/schema/request/device_report')->tx->res->json;
    my $jv = JSON::Validator->new()->load_and_validate_schema($schema);
    my @errors = $jv->validate($report);
    is scalar @errors, 0, 'no errors';
}

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
