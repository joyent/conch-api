use strict;
use warnings;
use Test::Conch;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Deep::JSON;
use Conch::UUID 'create_uuid_str';

use constant SPEC_URL => 'https://json-schema.org/draft/2019-09/schema';

my $t_super = Test::Conch->new;
my $super_user = $t_super->load_fixture('super_user');
my $ro_user = $t_super->load_fixture('ro_user');
my $other_user = $t_super->generate_fixtures('user_account');

$t_super->authenticate(email => $super_user->email);

my $t_ro = Test::Conch->new(pg => $t_super->pg);
$t_ro->authenticate(email => $ro_user->email);
my $base_uri = $t_ro->ua->server->url; # used as the base uri for all requests with ro user's app

my $t_other = Test::Conch->new(pg => $t_super->pg);
$t_other->authenticate(email => $other_user->email);

$t_ro->post_ok('/json_schema/fo~o/b~ar', json => {})
  ->status_is(404)
  ->json_is({ error => 'Route Not Found' });

$t_ro->post_ok('/json_schema/foo/bar', json => {})
  ->status_is(400)
  ->json_schema_is('RequestValidationError')
  ->json_cmp_deeply('/details', [
    {
      data_location => '',
      schema_location => '/allOf/1/required',
      absolute_schema_location => $base_uri.'json_schema/request/JSONSchema#/allOf/1/required',
      error => 'missing property: description',
    }
  ]);

$t_ro->post_ok('/json_schema/foo/bar', json => {
    '$schema' => 'http://json-schema.org/draft-07/schema#',
    description => 'hi',
  })
  ->status_is(400)
  ->json_schema_is('RequestValidationError')
  ->json_cmp_deeply('/details', [
    {
      data_location => '/$schema',
      schema_location => '/allOf/0/properties/$schema/const',
      absolute_schema_location => $base_uri.'json_schema/request/JSONSchema_recurse#/properties/$schema/const',
      error => 'value does not match',
    }
  ]);

$t_ro->post_ok('/json_schema/foo/bar', json => { '$schema' => SPEC_URL, description => '' })
  ->status_is(400)
  ->json_schema_is('RequestValidationError')
  ->json_cmp_deeply('/details', [
    {
      data_location => '/description',
      schema_location => '/allOf/1/properties/description/$ref/minLength',
      absolute_schema_location => $base_uri.'json_schema/common/non_empty_string#/minLength',
      error => 'length is less than 1',
    }
  ]);

my $base_schema = {
  '$schema' => SPEC_URL,
  description => '...',
  type => 'object',
  required => ['a'],
};

$t_ro->post_ok('/json_schema/foo/bar', json => { $base_schema->%*, required => 'not an arrayref' })
  ->status_is(400)
  ->json_schema_is('RequestValidationError')
  ->json_cmp_deeply('/details', [
    {
      data_location => '/required',
      schema_location => '/allOf/0/$ref/allOf/2/$ref/properties/required/$ref/type',
      absolute_schema_location => 'https://json-schema.org/draft/2019-09/meta/validation#/$defs/stringArray/type',
      error => 'wrong type (expected array)',
    }
  ]);

$t_ro->post_ok('/json_schema/foo/bar', json => {
    $base_schema->%*,
    '$id' => 'foobar',
    '$anchor' => 'foo',
    definitions => { alpha => {} },
  })
  ->status_is(400)
  ->json_schema_is('RequestValidationError')
  ->json_cmp_deeply('/details', [
    map +{
      data_location => '/'.$_,
      schema_location => '/allOf/0/properties/'.$_,
      # should be the same as '/json_schema/request/JSONSchema#/allOf/0/properties/'.$_
      absolute_schema_location => $base_uri.'json_schema/request/JSONSchema_recurse#/properties/'.$_,
      error => 'property not permitted',
    },
    qw($anchor $id definitions),
  ]);

$t_ro->post_ok('/json_schema/foo/bar', json => {
    $base_schema->%*,
    additionalProperties => {
      '$id' => 'foobar',
      '$anchor' => 'foo',
      definitions => { alpha => {} },
    },
  })
  ->status_is(400)
  ->json_cmp_deeply('/details', [
    map +{
      data_location => '/additionalProperties/'.$_,
      schema_location => re(qr'^/allOf/0/.*/properties/'.quotemeta($_).'$'),
      absolute_schema_location => $base_uri.'json_schema/request/JSONSchema_recurse#/properties/'.$_,
      error => 'property not permitted',
    },
    qw($anchor $id definitions),
  ]);


$t_ro->post_ok('/json_schema/hardware_product/specification', json => { description => 'spec schema' })
  ->status_is(201)
  ->location_like(qr!^/json_schema/${\Conch::UUID::UUID_FORMAT}$!)
  ->header_is('Content-Location', '/json_schema/hardware_product/specification/1');

$t_ro->delete_ok('/json_schema/hardware_product/specification/1')
  ->status_is(409)
  ->json_is({ error => 'JSON Schema cannot be deleted: /json_schema/hardware_product/specification/latest will be unresolvable' });

$t_ro->app->db_json_schemas->search({ type => 'hardware_product', name => 'specification' })->delete;


$t_ro->post_ok('/json_schema/foo/bar', json => {
    $base_schema->%*,
    properties => {
      a => { '$ref' => '#/properties/b' },
    },
  })
  ->status_is(409)
  ->json_is({ error => 'schema contains prohibited $ref: #/properties/b' });

my $schema1 = {
  $base_schema->%*,
  description => 'this is my first foo-bar schema',
  properties => {
    a => { type => 'string' },
  },
};

$t_ro->post_ok('/json_schema/request/foo', json => $schema1)
  ->status_is(409)
  ->json_is({ error => 'type "request" is prohibited' });

$t_ro->post_ok('/json_schema/foo/bar', json => $schema1)
  ->status_is(201)
  ->location_like(qr!^/json_schema/${\Conch::UUID::UUID_FORMAT}$!)
  ->header_is('Content-Location', '/json_schema/foo/bar/1');
my ($schema1_id) = $t_ro->tx->res->headers->location =~ m!/([^/]+)$!;

my @db_rows = $t_ro->app->db_json_schemas->hri->all;
cmp_deeply(
  \@db_rows,
  [{
    id => $schema1_id,
    type => 'foo',
    name => 'bar',
    version => 1,
    body => json($schema1), # deserializer hook not called due to ->hri
    created_user_id => $ro_user->id,
    created => ignore,
    deactivated => undef,
  }],
  'database looks good',
);

$t_ro->get_ok('/json_schema/foo/bar/blah')
  ->status_is(404)
  ->json_is({ error => 'Route Not Found' });

$t_ro->get_ok($_)
  ->status_is(404)
  ->json_is({ error => 'Entity Not Found' })
  ->log_debug_is('Could not find JSON Schema '.(m{/json_schema/(.*)$})[0])
  foreach
    '/json_schema/'.create_uuid_str,
    '/json_schema/foo/bar/2',
    '/json_schema/blah/baz/latest',
    '/json_schema/blah/bar/latest',
    '/json_schema/foo/baz/latest';

$t_ro->get_ok($_)
  ->status_is(200)
  ->header_is('Last-Modified', Conch::Time->new($db_rows[0]->{created})->strftime('%a, %d %b %Y %T GMT'))
  ->header_is('Content-Type', 'application/schema+json')
  ->json_schema_is('JSONSchema')
  ->json_cmp_deeply({
    $schema1->%*,
    '$id' => re(qr{/json_schema/foo/bar/1$}),
    '$comment' => 'created by ro_user <ro_user@conch.joyent.us>',
    'x-json_schema_id' => $schema1_id,
  })
  foreach
    '/json_schema/'.$schema1_id,
    '/json_schema/foo/bar/1',
    '/json_schema/foo/bar/latest';

$t_other->get_ok($_)
  ->status_is(200)
  ->header_is('Last-Modified', Conch::Time->new($db_rows[0]->{created})->strftime('%a, %d %b %Y %T GMT'))
  ->header_is('Content-Type', 'application/schema+json')
  ->json_schema_is('JSONSchema')
  ->json_cmp_deeply({
    $schema1->%*,
    '$id' => re(qr{/json_schema/foo/bar/1$}),
    '$comment' => 'created by ro_user <ro_user@conch.joyent.us>',
    'x-json_schema_id' => $schema1_id,
  })
  foreach
    '/json_schema/'.$schema1_id,
    '/json_schema/foo/bar/1',
    '/json_schema/foo/bar/latest';

my $schema2 = {
  $base_schema->%*,
  description => 'this is my second foo-bar schema',
  properties => {
    a => { type => 'string' },
    n => { type => 'integer' },
  },
};

$t_ro->post_ok('/json_schema/foo/bar', json => $schema2)
  ->status_is(201)
  ->location_like(qr!^/json_schema/${\Conch::UUID::UUID_FORMAT}$!)
  ->header_is('Content-Location', '/json_schema/foo/bar/2');
my ($schema2_id) = $t_ro->tx->res->headers->location =~ m!/([^/]+)$!;

@db_rows = $t_ro->app->db_json_schemas->hri->all;

$t_ro->get_ok($_)
  ->status_is(200)
  ->header_is('Last-Modified', Conch::Time->new($db_rows[1]->{created})->strftime('%a, %d %b %Y %T GMT'))
  ->header_is('Content-Type', 'application/schema+json')
  ->json_schema_is('JSONSchema')
  ->json_cmp_deeply({
    $schema2->%*,
    '$id' => re(qr{/json_schema/foo/bar/2$}),
    '$comment' => 'created by ro_user <ro_user@conch.joyent.us>',
    'x-json_schema_id' => $schema2_id,
  })
  foreach
    '/json_schema/'.$schema2_id,
    '/json_schema/foo/bar/2',
    '/json_schema/foo/bar/latest';

$t_ro->get_ok('/json_schema/blah/baz')
  ->status_is(404)
  ->json_is({ error => 'Entity Not Found' });

$t_ro->get_ok('/json_schema/blah/bar')
  ->status_is(404)
  ->json_is({ error => 'Entity Not Found' });

$t_ro->get_ok('/json_schema/foo/baz')
  ->status_is(404)
  ->json_is({ error => 'Entity Not Found' });

$t_ro->post_ok('/json_schema/foo/alpha', json => { $schema1->%*, description => 'this is my first foo-alpha schema' })
  ->status_is(201)
  ->location_like(qr!^/json_schema/${\Conch::UUID::UUID_FORMAT}$!)
  ->header_is('Content-Location', '/json_schema/foo/alpha/1');
my ($schema3_id) = $t_ro->tx->res->headers->location =~ m!/([^/]+)$!;

$t_ro->get_ok('/json_schema/foo')
  ->status_is(200)
  ->json_schema_is('JSONSchemaDescriptions')
  ->json_cmp_deeply([
    {
      id => $schema3_id,
      '$id' => '/json_schema/foo/alpha/1',
      description => 'this is my first foo-alpha schema',
      type => 'foo',
      name => 'alpha',
      version => 1,
      created => ignore,
      created_user => { map +($_ => $ro_user->$_), qw(id name email) },
    },
    {
      id => $schema1_id,
      '$id' => '/json_schema/foo/bar/1',
      description => 'this is my first foo-bar schema',
      type => 'foo',
      name => 'bar',
      version => 1,
      created => Conch::Time->new($db_rows[0]->{created})->to_string,
      created_user => { map +($_ => $ro_user->$_), qw(id name email) },
    },
    {
      id => $schema2_id,
      '$id' => '/json_schema/foo/bar/2',
      description => 'this is my second foo-bar schema',
      type => 'foo',
      name => 'bar',
      version => 2,
      created => Conch::Time->new($db_rows[1]->{created})->to_string,
      created_user => { map +($_ => $ro_user->$_), qw(id name email) },
    },
  ]);
my $metadata = $t_ro->tx->res->json;

$t_other->get_ok('/json_schema/foo')
  ->status_is(200)
  ->json_schema_is('JSONSchemaDescriptions')
  ->json_cmp_deeply($metadata);

$t_ro->get_ok('/json_schema/foo/bar')
  ->status_is(200)
  ->json_schema_is('JSONSchemaDescriptions')
  ->json_cmp_deeply([ $metadata->@[1..2] ]);

$t_ro->get_ok('/json_schema/foo/alpha')
  ->status_is(200)
  ->json_schema_is('JSONSchemaDescriptions')
  ->json_cmp_deeply([ $metadata->[0] ]);

$t_ro->delete_ok('/json_schema/foo/bar/latest')
  ->status_is(404)
  ->json_is({ error => 'Route Not Found' });

$t_other->delete_ok($_)
  ->status_is(403)
  ->log_debug_is('User lacks the required access for '.$_)
  foreach
    '/json_schema/'.$schema2_id,
    '/json_schema/foo/bar/2';

$t_ro->delete_ok('/json_schema/foo/bar/2')
  ->status_is(204)
  ->log_debug_is('Deactivated JSON Schema id '.$schema2_id.' (/json_schema/foo/bar/2); latest of this type and name is now /json_schema/foo/bar/1');

$t_ro->delete_ok('/json_schema/'.$schema2_id)
  ->status_is(410);

$t_ro->get_ok('/json_schema/foo/bar/2')
  ->status_is(410);

$t_ro->get_ok('/json_schema/foo/bar/latest')
  ->status_is(200)
  ->header_is('Content-Type', 'application/schema+json')
  ->json_schema_is('JSONSchema')
  ->json_is('/x-json_schema_id', $schema1_id);

$t_ro->get_ok('/json_schema/foo/bar')
  ->status_is(200)
  ->json_schema_is('JSONSchemaDescriptions')
  ->json_cmp_deeply([ $metadata->[1] ]);

$t_ro->delete_ok('/json_schema/foo/bar/1')
  ->status_is(204)
  ->log_debug_is('Deactivated JSON Schema id '.$schema1_id.' (/json_schema/foo/bar/1); no schemas of this type and name remain');

$t_ro->get_ok('/json_schema/foo/bar/1')
  ->status_is(410);

$t_ro->get_ok('/json_schema/foo/bar/latest')
  ->status_is(410);

$t_ro->get_ok('/json_schema/foo/bar')
  ->status_is(410);

done_testing;
# vim: set sts=2 sw=2 et :
