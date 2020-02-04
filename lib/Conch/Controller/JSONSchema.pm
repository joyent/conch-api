package Conch::Controller::JSONSchema;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use feature 'current_sub';

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
        my $ref_uri = Mojo::URL->new($schema->{'$ref'});
        return if $ref_uri->is_abs;
        $ref_uri = $ref_uri->to_abs(JSON::Schema::Draft201909::Utilities::canonical_schema_uri($state));

        my @def_segments = split('/', $ref_uri->fragment//'');
        push @errors, 'invalid uri fragment "'.($ref_uri->fragment//'').'"' and return
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

    # hack! remove when adding get-from-database functionality
    if ($c->req->url->path =~ qr{^/json_schema/hardware_product/specification/(?:1|latest)$}) {
        $bundled_schema->{'$id'} = $c->url_for->path('1')->to_abs;
        delete $bundled_schema->{deprecated};
    }

    $c->res->headers->content_type('application/schema+json');
    return $c->status(200, $bundled_schema);
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
