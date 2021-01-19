package Conch::Controller::JSONSchema;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::JSON qw(to_json from_json);

=pod

=head1 NAME

Conch::Controller::JSONSchema

=head1 METHODS

=head2 get_from_disk

Get a query parameters, request, response, common or device_report JSON Schema (from
F<query_params.yaml>, F<request.yaml>, F<response.yaml>, F<common.yaml>, or F<device_report.yaml>,
respectively). Bundles all the referenced definitions together in the returned body response.

=cut

sub get_from_disk ($c) {
    # set Last-Modified header; return 304 if If-Modified-Since is recent enough.
    # For now, just use the server start time. We could do something more sophisticated with
    # the timestamps on the schema file(s), but this is fiddly and involves following all $refs
    # to see what files they came from.
    return $c->status(304) if $c->is_fresh(last_modified => $c->startup_time->epoch);

    my $type = $c->stash('json_schema_type');
    my $name = $c->stash('json_schema_name');
    my $js = $c->json_schema_validator;

    my $initial_uri = $type.'.yaml#/$defs/'.$name;
    my $base_schema = $js->get($initial_uri) // $js->get($c->req->url);

    if (not $base_schema) {
        $c->log->warn('Could not find '.$type.' schema '.$name);
        return $c->status(404);
    }

    my (@errors, $seen_uris, $bundled_schema);
    my $ref_callback = sub ($schema, $state) {
        # we special-case this reference to a resource maintained dynamically
        return if $schema->{'$ref'} eq '/json_schema/hardware_product/specification/latest';

        my $ref_uri = Mojo::URL->new($schema->{'$ref'});
        return if $ref_uri->is_abs;
        $ref_uri = $ref_uri->to_abs(JSON::Schema::Draft201909::Utilities::canonical_schema_uri($state));

        my @def_segments = split('/', $ref_uri->fragment//'');
        push @errors, 'invalid uri fragment "'.($ref_uri->fragment//'').'" (from $ref "'.$schema->{'$ref'}.'")' and return
            if @def_segments < 3 or ($def_segments[0] ne '' and $def_segments[1] ne '$defs');
        my $def_name = $def_segments[2];
        my ($def_type) = $ref_uri->path =~ m!(\w+)\.yaml!;

        # rewrite the $ref from (FILE)?#/$defs/NAME to /json_schema/TYPE/NAME
        $schema->{'$ref'} = Mojo::URL->new('/json_schema/'.$def_type .'/'.$def_name);
        $schema->{'$ref'}->fragment(join('/', '', @def_segments[3..$#def_segments]))
            if @def_segments > 3;

        # now fetch the target and add it to $defs, adding $id
        $ref_uri->fragment(join('/', @def_segments[0..2]));
        return if $seen_uris->{$ref_uri}++;

        my $def_schema = $js->get($ref_uri);
        push @errors, 'cannot find schema for "'.$ref_uri.'"' and return if not defined $def_schema;

        push @errors, 'namespace collision: '.$ref_uri.' conflicts with pre-existing '.$def_name.' definition' and return
            if exists $bundled_schema->{'$defs'}{$def_name};

        $js->traverse($bundled_schema->{'$defs'}{$def_name} = $def_schema,
            { callbacks => { '$ref' => __SUB__ }, canonical_schema_uri => $ref_uri });

        # add the $id after we traverse, so we don't confuse the uri resolver
        $def_schema->{'$id'} = '/json_schema/'.$def_type.'/'.$def_name;
    };

    my $state = $js->traverse($base_schema,
        { callbacks => { '$ref' => $ref_callback }, canonical_schema_uri => $initial_uri });

    if (@errors) {
        $c->log->fatal('errors when resolving /json_schema/'.$type.'/'.$name.': '.join(', ', @errors));
        return $c->status(400, { error => 'cannot resolve schema' });
    }

    $bundled_schema = { $base_schema->%*, ($bundled_schema//{})->%* };

    # the canonical location of this document -- which should be the same URL used to get here
    $bundled_schema->{'$id'} = $c->url_for('/json_schema/'.$type.'/'.$name)->to_abs;
    $bundled_schema->{'$schema'} //= 'https://json-schema.org/draft/2019-09/schema';

    $c->res->headers->content_type('application/schema+json');
    return $c->status(200, $bundled_schema);
}

=head2 create

Stores a new JSON Schema in the database.

The type names used in L</get_from_disk> (C<query_params>, C<request>, C<response>, C<common>,
C<device_report>) cannot be used.

The C<$id>, C<$anchor>, C<definitions> and C<dependencies> keywords are prohibited anywhere in the
document. C<description> is required at the top level of the document.

=cut

sub create ($c) {
  my $input = $c->stash('request_data');

  # things could get really confusing if we had schemas with this type in the database
  return $c->status(409, { error => 'type "'.$c->stash('json_schema_type').'" is prohibited' })
    if $c->stash('json_schema_type') =~ /^(?:query_params|request|response|common|device_report)$/;

  # the (non-canonical) URI of the about-to-be-created resource
  my $base_uri = join '/', '/json_schema', $c->stash('json_schema_type'), $c->stash('json_schema_name'), 'latest';

  my @refs;
  JSON::Schema::Draft201909->new->traverse($input, {
    callbacks => { '$ref' => sub ($schema, $state) { push @refs, $schema->{'$ref'} } },
    canonical_schema_uri => $base_uri,
  });

  # find all $refs and add them to the document definitions...
  # but for now, we will prohibit all $refs entirely.
  if (@refs) {
    return $c->status(409, { error => 'schema contains prohibited $ref'
      .(@refs > 1 ? 's' : '').': '. join(', ', @refs) });
  }

  # if submitting a new hardware_product.specification schema, make sure all existing
  # hardware_product.specification data successfully evaluates against it
  if ($base_uri eq '/json_schema/hardware_product/specification/latest') {
    my $version = $c->db_json_schemas
      ->resource('hardware_product', 'specification', 'latest')
      ->get_column('version')->single;
    $version = ($version // 0) + 1;

    my $uri = $base_uri =~ s/latest$/$version/r;
    my $schema = +{ $input->%*, '$id' => $uri };

    my $js = JSON::Schema::Draft201909->new(output_format => 'terse', validate_formats => 1);
    $js->add_schema($uri, $schema);

    my $hw_rs = $c->db_hardware_products->active->columns([qw(id name specification)])->hri;
    while (my $hw_row = $hw_rs->next) {
      if (not (my $result = $js->evaluate(from_json($hw_row->{specification}), $uri))) {
        my @errors = map +{
          data_location => '/specification'.$_->{instanceLocation},
          schema_location => $_->{keywordLocation},
          absolute_schema_location => $_->{absoluteKeywordLocation},
          error => $_->{error},
        }, $result->TO_JSON->{errors}->@*;

        $c->stash('response_schema', 'ValidationError');
        return $c->status(409, {
          error => 'proposed hardware_product specification schema does not successfully evaluate against existing specification for hardware_product id \''.$hw_row->{id}.'\' ('.$hw_row->{name}.')',
          schema => '/json_schema/hardware_product/specification/'.$version,
          details => \@errors,
        });
      }
    }
  }

  my $row = $c->db_json_schemas->create({
    type => $c->stash('json_schema_type'),
    name => $c->stash('json_schema_name'),
    version => \[
      'coalesce((select max(version) from json_schema where type = ? and name = ?),0) + 1',
      $c->stash('json_schema_type'), $c->stash('json_schema_name'),
    ],
    body => to_json($input),
    created_user_id => $c->stash('user_id'),
  });

  my $path = $row->canonical_path;
  $c->log->info('created json schema '.$row->id.' at '.$path);
  $c->res_location('/json_schema/'.$row->id);
  $c->res->headers->content_location($c->url_for($path));
  $c->status(201);
}

=head2 find_json_schema

Chainable action that uses the C<json_schema_id>, C<json_schema_type>, C<json_schema_name>, and
C<json_schema_version> values provided in the stash (usually via the request URL) to look up a
JSON Schema, and stashes a simplified query (by C<id>) to get to it in C<json_schema_rs>, and
the id itself in C<json_schema_id>.

If the resource is referenced as C</json_schema/:id> or as C</json_schema/:type/:name/:version>, the
exact schema will be retrieved, even if it is deactivated; if it is referenced by
C</json_schema/:type/:name/latest>, the latest B<active> schema of that type-name series will be
retrieved.

=cut

sub find_json_schema ($c) {
  my $rs = $c->db_json_schemas;
  if (my $id = $c->stash('json_schema_id')) {
    $rs = $rs->search({ id => $id });
  }
  else {
    $rs = $rs->resource($c->stash('json_schema_type'), $c->stash('json_schema_name'), $c->stash('json_schema_version'));
  }

  if (not $rs->exists) {
    $c->log->debug('Could not find JSON Schema '.($c->stash('json_schema_id')
      // join('/', $c->stash('json_schema_type'), $c->stash('json_schema_name'), $c->stash('json_schema_version'))));
    return $c->status(404);
  }

  if (($c->stash('json_schema_version')//'') eq 'latest') {
    $rs = $rs->active;
    return $c->status(410) if not $rs->exists;
  }

  # we don't fetch the id earlier, because a query for /latest with 'active' can get a different row
  my $id = $rs->get_column('id')->single;
  $rs = $c->db_json_schemas->search({ 'json_schema.id' => $id });
  $c->stash('json_schema_rs', $rs);
  $c->stash('json_schema_id', $id);
  return 1;
}

=head2 assert_active

A chainable route that will ensure that the JSON Schema referenced by the C<json_schema_rs> stash
variable is not deactivated (otherwise, a C<410 Gone> response will be issued).

=cut

sub assert_active ($c) {
  return $c->stash('json_schema_rs')->active->exists ? 1 : $c->status(410);
}

=head2 get_single

Gets a single JSON Schema specification document.

=cut

sub get_single ($c) {
  my $row = $c->stash('json_schema_rs')->with_created_user->single;

  return $c->status(304) if $c->is_fresh(last_modified => $row->created->epoch);

  # TODO optionally fetch all referenced schemas as well, with ?bundle=1

  my $id_generator = sub ($row) { $c->url_for($row->canonical_path)->to_abs->to_string };
  my $data = $row->schema_document($id_generator);

  $c->res->headers->content_type('application/schema+json');
  $c->status(200, $data);
}

=head2 delete

Deactivates the database entry for a single JSON Schema, rendering it unusable. This operation
is not permitted until all references from other documents have been removed, with the
exception of references using C<.../latest> which will now resolve to a different document (and
paths within that document will be re-verified).

If this JSON Schema was the latest of its series (C</json_schema/foo/bar/latest>), then that
C<.../latest> link will now resolve to an earlier version in the series.

=cut

sub delete ($c) {
  my $metadata = $c->stash('json_schema_rs')->columns([qw(type name version created_user_id)])->hri->single;

  if (not $c->is_system_admin and $metadata->{created_user_id} ne $c->stash('user_id')) {
    $c->log->debug('User lacks the required access for '.$c->req->url->path);
    return $c->status(403);
  }

  my $json_schema_id = $c->stash('json_schema_id');

  my $hardware_product_rs = $c->db_hardware_product_json_schemas
    ->search({ json_schema_id => $json_schema_id });
  if ($hardware_product_rs->exists) {
    $c->stash('response_schema', 'HardwareProductJSONSchemaDeleteError');
    return $c->status(409, {
      error => 'JSON Schema cannot be deleted: referenced by hardware',
      hardware_product_ids => [ $hardware_product_rs->get_column('hardware_product_id')->all ],
    });
  }

  my $latest = $c->db_json_schemas
    ->active
    ->resource($metadata->@{qw(type name)}, 'latest')
    ->search({ id => { '!=' => $json_schema_id } })
    ->columns([qw(id version)])->hri->single;

  return $c->status(409, { error => 'JSON Schema cannot be deleted: /json_schema/hardware_product/specification/latest will be unresolvable' })
    if $metadata->{type} eq 'hardware_product' and $metadata->{name} eq 'specification' and not $latest->{id};

  $c->stash('json_schema_rs')->deactivate;

  $c->log->debug('Deactivated JSON Schema id '.$json_schema_id
    .' (/json_schema/'.join('/', $metadata->@{qw(type name version)}).')'
    .(  !$latest ? '; no schemas of this type and name remain'
      : $latest->{version} > $metadata->{version} ? ''
      : ('; latest of this type and name is now /json_schema/'
         .join('/', $metadata->@{qw(type name)}, $latest->{version}))));

  $c->status(204);
}

=head2 get_metadata

Gets meta information about all JSON Schemas in a particular type and name series,
optionally fetching active schemas only.

=cut

sub get_metadata ($c) {
  my $params = $c->stash('query_params');

  my $rs = $c->db_json_schemas->type($c->stash('json_schema_type'));
  $rs = $rs->name($c->stash('json_schema_name')) if $c->stash('json_schema_name');

  return $c->status(404) if not $rs->exists;

  if ($params->{active_only}) {
    $rs = $rs->active;
    return $c->status(410) if not $rs->exists;
  }

  $rs = $rs
    ->with_latest_flag  # closes off the resultset as a subquery!
    ->with_description
    ->with_created_user
    ->remove_columns([ 'body' ])
    ->order_by([ qw(json_schema.name json_schema.version) ]);

  if ($params->{with_hardware_products}) {
    $rs = $rs
      ->search(undef, { join => { hardware_product_json_schemas => 'hardware_product' }, collapse => 1 })
      ->add_columns({
        map +('hardware_product_json_schemas.hardware_product.'.$_ => 'hardware_product.'.$_),
          qw(id name alias generation_name sku created updated)
      })
      ->order_by('hardware_product.name')
  }

  $c->status(200, [ $rs->all ]);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut

# vim: set sts=2 sw=2 et :
