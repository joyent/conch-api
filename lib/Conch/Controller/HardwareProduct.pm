package Conch::Controller::HardwareProduct;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';
use Mojo::JSON qw(to_json from_json);

=pod

=head1 NAME

Conch::Controller::HardwareProduct

=head1 METHODS

=head2 get_all

Get a list of all available hardware products.

Response uses the HardwareProducts json schema.

=cut

sub get_all ($c) {
    my @hardware_products_raw =
        map +{
            $_->%*,
            created => Conch::Time->new($_->{created}),
            updated => Conch::Time->new($_->{updated}),
        },
        $c->db_hardware_products
            ->active
            ->columns([qw(id name alias generation_name sku created updated)])
            ->order_by('name')
            ->hri
            ->all;

    $c->status(200, \@hardware_products_raw);
}

=head2 find_hardware_product

Chainable action that uses the C<hardware_product_id_or_other> value provided in the stash
(usually via the request URL) to look up a hardware_product, and stashes the query to get to it
in C<hardware_product_rs>.

Supported identifiers in path are: C<id>, C<sku>, C<name>, and C<alias>.

=cut

sub find_hardware_product ($c) {
    my $identifier = $c->stash('hardware_product_id_or_other');
    my $hardware_product_rs = $c->db_hardware_products;

    # identifier can be id, sku, name, alias
    if (is_uuid($identifier)) {
        $c->log->debug('Looking up a hardware product by id '.$identifier);
        $c->stash('hardware_product_id', $identifier);
        $hardware_product_rs = $hardware_product_rs->search({ 'hardware_product.id' => $identifier });
    }
    else {
        $c->log->debug('Looking up a hardware product by sku,name,alias '.$identifier);
        $hardware_product_rs = $hardware_product_rs->search({
            -or => [ map +{ 'hardware_product.'.$_ => $identifier }, qw(sku name alias) ],
        });
    }

    return $c->status(404) if not $hardware_product_rs->exists;

    $hardware_product_rs = $hardware_product_rs->active;
    return $c->status(410) if not $hardware_product_rs->exists;

    return $c->status(409, { error => 'there is more than one match' }) if $hardware_product_rs->count > 1;

    $c->stash('hardware_product_rs', $hardware_product_rs);
    return 1;
}

=head2 get

Get the details of a single hardware product.

Response uses the HardwareProduct json schema.

=cut

sub get ($c) {
    my $hardware_product = $c->stash('hardware_product_rs')->single;
    $c->res_location('/hardware_product/'.$hardware_product->id);
    $c->status(200, $hardware_product);
}

=head2 create

Creates a new hardware_product.

=cut

sub create ($c) {
    my $input = $c->stash('request_data');

    for my $key (qw(name alias sku)) {
        next if not $input->{$key};
        if ($c->db_hardware_products->active->search({ $input->%{$key} })->exists) {
            $c->log->debug('Failed to create hardware product: unique constraint violation for '.$key);
            return $c->status(409, { error => "Unique constraint violated on '$key'" });
        }
    }

    return $c->status(409, { error => 'hardware_vendor_id does not exist' })
      if not $c->db_hardware_vendors->active->search({ id => $input->{hardware_vendor_id} })->exists;
    return $c->status(409, { error => 'validation_plan_id does not exist' })
      if not $c->db_legacy_validation_plans->active->search({ id => $input->{validation_plan_id} })->exists;

    $input->{legacy_validation_plan_id} = delete $input->{validation_plan_id};
    $input->{specification} = to_json($input->{specification}) if defined $input->{specification};

    my $hardware_product = $c->txn_wrapper(sub ($c) {
        $c->db_hardware_products->create($input);
    });

    # if the result code was already set, we errored and rolled back the db..
    return $c->status(400) if not $hardware_product;

    $c->log->debug('Created hardware product id '.$hardware_product->id);
    $c->res_location('/hardware_product/'.$hardware_product->id);
    $c->status(201);
}

=head2 update

Updates an existing hardware_product.

=cut

sub update ($c) {
    my $input = $c->stash('request_data');
    my $hardware_product = $c->stash('hardware_product_rs')->single;

    for my $key (qw(name alias sku)) {
        next if not defined $input->{$key};
        next if $input->{$key} eq $hardware_product->$key;

        if ($c->db_hardware_products->active->search({ $input->%{$key} })->exists) {
            $c->log->debug('Failed to create hardware product: unique constraint violation for '.$key);
            return $c->status(409, { error => "Unique constraint violated on '$key'" });
        }
    }

    return $c->status(409, { error => 'hardware_vendor_id does not exist' })
      if exists $input->{hardware_vendor_id}
        and $input->{hardware_vendor_id} ne $hardware_product->hardware_vendor_id
        and not $c->db_hardware_vendors->active->search({ id => $input->{hardware_vendor_id} })->exists;

    return $c->status(409, { error => 'validation_plan_id does not exist' })
      if exists $input->{validation_plan_id}
        and $input->{validation_plan_id} ne $hardware_product->legacy_validation_plan_id
        and not $c->db_legacy_validation_plans->active->search({ id => $input->{validation_plan_id} })->exists;

    $input->{legacy_validation_plan_id} = delete $input->{validation_plan_id} if exists $input->{validation_plan_id};
    $input->{specification} = to_json($input->{specification}) if defined $input->{specification};

    $c->txn_wrapper(sub ($c) {
        $hardware_product->update({ $input->%*, updated => \'now()' }) if $input->%*;
        $c->log->debug('Updated hardware product '.$hardware_product->id);
        return 1;
    })
    or return $c->res->code(400);

    $c->status(204, '/hardware_product/'.$hardware_product->id);
}

=head2 delete

=cut

sub delete ($c) {
    my $id = $c->stash('hardware_product_rs')->get_column('id')->single;
    $c->stash('hardware_product_rs')->deactivate;

    my $device_count = $c->stash('hardware_product_rs')->related_resultset('devices')->count;
    $c->log->debug('Deleted hardware product '.$id.' ('.$device_count.' devices using this hardware)');
    return $c->status(204);
}

=head2 set_specification

Uses the URI query parameter C<path> as a json pointer to determine the path within the
C<specification> property to operate on. New data is written, and existing data is overwritten
without regard to type (so long as it conforms to the schema).

After the update operation, the C<specification> property must validate against
the schema at C</json_schema/hardware_product/specification/latest>.

=cut

sub set_specification ($c) {
  my $hardware_product_id = $c->stash('hardware_product_rs')->get_column('id')->single;
  my $rs = $c->db_hardware_products->search({ id => $hardware_product_id });
  my $json = to_json($c->stash('request_data'));
  my $jsonp = $c->stash('query_params')->{path};

  my $specification_clause = $jsonp ? do {
    my @path = map s!~1!/!gr =~ s!~0!~!gr, split('/', $jsonp, -1);
    \[ 'jsonb_set(specification, ?, ?)', '{'.join(',', map '"'.$_.'"', @path[1..$#path]).'}', $json ]
  } : $json;

  # update the specification field in a transaction, then read it back and see if it validates
  # against the schema -- rolling back and returning an error if it does not.
  my $rendered;
  my $result = $c->txn_wrapper(sub ($c) {
    $rs->update({ specification => $specification_clause });
    my $new_specification = from_json($rs->get_column('specification')->single);

    my $js = $c->json_schema_validator;
    my $spec_uri = '/json_schema/hardware_product/specification/latest';  # NOT absolute
    if (not my $result = $js->evaluate($new_specification, $spec_uri)) {
      my @errors = $c->normalize_evaluation_result($result);
      $c->stash('response_schema', 'ValidationError');
      $c->status(409, {
        error => 'new specification field did not match required format',
        details => \@errors,
        schema => scalar($js->get($spec_uri.'#/$id')),  # /<version>, not /latest
        data => $new_specification,
      });

      $rendered = 1;
      die 'rollback';
    }

    return 1;
  });

  return $rendered ? () : $c->status(400) if not $result;

  $c->res_location('/hardware_product/'.$hardware_product_id);
  $c->status(204);
}

=head2 delete_specification

Uses the URI query parameter C<path> as a json pointer to determine the path within the
C<specification> property to operate on. All of the data at the indicated path is deleted.

After the delete operation, the C<specification> property must validate against
the schema at C</json_schema/hardware_product/specification/latest>.

=cut

sub delete_specification ($c) {
  my $params = $c->stash('query_params');

  my $hardware_product_id = $c->stash('hardware_product_rs')->get_column('id')->single;
  my $rs = $c->db_hardware_products->search({ id => $hardware_product_id });
  my $jsonp = $params->{path};

  my $specification_clause = $jsonp ? do {
    my @path = map s!~1!/!gr =~ s!~0!~!gr, split('/', $jsonp, -1);
    \[ 'specification #- ?', '{'.join(',', map '"'.$_.'"', @path[1..$#path]).'}' ]
  } : undef;

  my $rendered;
  my $result = $c->txn_wrapper(sub ($c) {
    $rs->update({ specification => $specification_clause });
    my $new_specification = from_json($rs->get_column('specification')->single);

    my $js = $c->json_schema_validator;
    my $spec_uri = '/json_schema/hardware_product/specification/latest';  # NOT absolute
    if (not my $result = $js->evaluate($new_specification, $spec_uri)) {
      my @errors = $c->normalize_evaluation_result($result);
      $c->stash('response_schema', 'ValidationError');
      $c->status(409, {
        error => 'new specification field did not match required format',
        details => \@errors,
        schema => scalar($js->get($spec_uri.'#/$id')),  # /<version>, not /latest
        data => $new_specification,
      });

      $rendered = 1;
      die 'rollback';
    }

    return 1;
  });

  return $rendered ? () : $c->status(400) if not $result;

  $c->res_location('/hardware_product/'.$hardware_product_id);
  $c->status(204);
}

=head2 add_json_schema

=cut

sub add_json_schema ($c) {
  my $hardware_product_id = $c->stash('hardware_product_id') // $c->stash('hardware_product_rs')->get_column('id')->single;
  my $json_schema_id = $c->stash('json_schema_id');

  return $c->status(204) if $c->db_hardware_product_json_schemas->search({
    hardware_product_id => $hardware_product_id,
    json_schema_id => $json_schema_id,
  })->exists;

  $c->db_hardware_product_json_schemas->create({
    hardware_product_id => $hardware_product_id,
    json_schema_id => $json_schema_id,
    added_user_id => $c->stash('user_id'),
  });

  $c->res->headers->location('/hardware_product/'.$hardware_product_id.'/json_schema');
  return $c->status(201);
}

=head2 get_json_schema_metadata

=cut

sub get_json_schema_metadata ($c) {
  my $hardware_product_id = $c->stash('hardware_product_id') //
    { '=' => $c->stash('hardware_product_rs')->get_column('id')->as_query };

  # we must select all json_schemas first in order for the 'latest' flag to be set properly
  my $rs = $c->db_json_schemas
    ->with_description
    ->remove_columns(['body'])
    ->with_latest_flag  # closes off the resultset as a subquery!
    ->search(
      { hardware_product_id => $hardware_product_id },
      { join => { hardware_product_json_schemas => 'added_user' } },
    )
    ->add_columns({
      (map +('added_user_'.$_ => 'added_user.'.$_), qw(id name email)),
      added => 'hardware_product_json_schemas.added',
    })
    ->with_created_user
    ->add_columns('description')
    ->remove_columns([ qw(body deactivated) ])
    ->order_by([map 'json_schema.'.$_, qw(type name version)]);

  $c->status(200, [ $rs->all ]);
}

=head2 remove_json_schema

=cut

sub remove_json_schema ($c) {
  my $json_schema_id = $c->stash('json_schema_id');
  my $rows_removed = $c->stash('hardware_product_rs')
    ->search_related('hardware_product_json_schemas', { json_schema_id => $json_schema_id })
    ->delete;

  if (not 0+$rows_removed) {
    $c->log->debug('JSON Schema '.$json_schema_id.' is not used by hardware product '.$c->stash('hardware_product_id_or_other'));
    return $c->status(404);
  }

  $c->log->debug('Removed JSON Schema '.$json_schema_id.' from hardware product '.$c->stash('hardware_product_id_or_other'));
  $c->status(204);
}

=head2 remove_all_json_schemas

=cut

sub remove_all_json_schemas ($c) {
  my $rows_removed = $c->stash('hardware_product_rs')
    ->related_resultset('hardware_product_json_schemas')
    ->delete;

  if (not 0+$rows_removed) {
    $c->log->debug('No JSON Schemas are used by hardware product '.$c->stash('hardware_product_id_or_other'));
    return $c->status(404);
  }

  $c->log->debug('Removed all JSON Schemas from hardware product '.$c->stash('hardware_product_id_or_other'));
  $c->status(204);
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
