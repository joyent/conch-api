package Conch::Controller::HardwareProduct;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use List::Util 'none';

=pod

=head1 NAME

Conch::Controller::HardwareProduct

=head1 METHODS

=head2 list

Get a list of all available hardware products.

Response uses the HardwareProducts json schema.

=cut

sub list ($c) {
    my @hardware_products_raw = $c->db_hardware_products
        ->active
        ->prefetch('hardware_product_profile')
        ->all;

    $c->status(200, \@hardware_products_raw);
}

=head2 find_hardware_product

Chainable action that looks up the object by id, sku, name or alias depending on the url
pattern, stashing the query to get to it in C<hardware_product_rs>.

=cut

sub find_hardware_product ($c) {
    my $hardware_product_rs = $c->db_hardware_products->active;

    # route restricts key to: sku, name, alias
    if (my $key = $c->stash('hardware_product_key')
            and my $value = $c->stash('hardware_product_value')) {
        $c->log->debug('Looking up a HardwareProduct by identifier ('.$key.' = '.$value.')');
        $hardware_product_rs = $hardware_product_rs
            ->search({ 'hardware_product.'.$key => $value });
    }
    elsif ($c->stash('hardware_product_id')) {
        $c->log->debug('Looking up a HardwareProduct by id '.$c->stash('hardware_product_id'));
        $hardware_product_rs = $hardware_product_rs
            ->search({ 'hardware_product.id' => $c->stash('hardware_product_id') });
    }
    else {
        return $c->status(500);
    }

    if (not $hardware_product_rs->exists) {
        $c->log->debug('Could not locate a valid hardware product with '
            .($c->stash('hardware_product_id') ? ('id '.$c->stash('hardware_product_id'))
                : ($c->stash('hardware_product_key').' '.$c->stash('hardware_product_value'))));
        return $c->status(404);
    }

    $c->stash('hardware_product_rs', scalar $hardware_product_rs);
    return 1;
}

=head2 get

Get the details of a single hardware product.

Response uses the HardwareProduct json schema.

=cut

sub get ($c) {
    my $rs = $c->stash('hardware_product_rs')
        ->prefetch('hardware_product_profile');

    $c->status(200, $rs->single);
}

=head2 create

Creates a new hardware_product, and possibly also a hardware_product_profile.

=cut

sub create ($c) {
    return $c->status(403) unless $c->is_system_admin;

    my $input = $c->validate_input('HardwareProductCreate');
    return if not $input;

    for my $key (qw(name alias sku)) {
        next unless $input->{$key};
        if ($c->db_hardware_products->active->search({ $key => $input->{$key} })->exists) {
            $c->log->debug('Failed to create hardware product: unique constraint violation for '.$key);
            return $c->status(400, { error => "Unique constraint violated on '$key'" });
        }
    }

    # backcompat only
    $input->{hardware_vendor_id} = delete $input->{vendor} if exists $input->{vendor};

    # create hardware_product_profile entries as well, as needed.
    my $hardware_product = $c->txn_wrapper(sub ($c) {
        $c->db_hardware_products->create($input);
    });

    # if the result code was already set, we errored and rolled back the db..
    return if $c->res->code;

    $c->log->debug('Created hardware product id '.$hardware_product->id.
        ($input->{hardware_product_profile}
          ? (' and hardware product profile id '.$hardware_product->hardware_product_profile->id)
          : '')
    );
    $c->status(303, '/hardware_product/'.$hardware_product->id);
}

=head2 update

Updates an existing hardware_product, possibly updating or creating a hardware_product_profile
as needed.

=cut

sub update ($c) {
    return $c->status(403) unless $c->is_system_admin;

    my $input = $c->validate_input('HardwareProductUpdate');
    return if not $input;

    my $hardware_product = $c->stash('hardware_product_rs')
        ->prefetch('hardware_product_profile')
        ->single;

    for my $key (qw(name alias sku)) {
        next unless defined $input->{$key};
        next if $input->{$key} eq $hardware_product->$key;

        if ($c->db_hardware_products->active->search({ $key => $input->{$key} })->exists) {
            $c->log->debug('Failed to create hardware product: unique constraint violation for '.$key);
            return $c->status(400, { error => "Unique constraint violated on '$key'" });
        }
    }

    # backcompat only
    $input->{hardware_vendor_id} = delete $input->{vendor} if exists $input->{vendor};

    $c->txn_wrapper(sub ($c) {
        $c->log->debug('start of transaction...');

        my $profile = delete $input->{hardware_product_profile};
        if ($profile and keys %$profile) {
            if (keys %$profile) {
                if ($hardware_product->hardware_product_profile) {
                    $hardware_product->hardware_product_profile->update({ %$profile, updated => \'now()', deactivated => undef });
                    $c->log->debug('Updated hardware_product_profile for hardware product '.$hardware_product->id);
                }
                else {
                    # when creating a new hardware product profile, we apply a stricter
                    # schema to the input
                    die 'rollback'
                        if not $c->validate_input('HardwareProductProfileCreate', $profile);

                    $hardware_product->create_related('hardware_product_profile', $profile);
                    $c->log->debug('Created new hardware_product_profile for hardware product '.$hardware_product->id);
                }
            }
        }

        $hardware_product->update({ %$input, updated => \'now()' }) if keys %$input;
        $c->log->debug('Updated hardware product '.$hardware_product->id);

        $c->log->debug('transaction ended successfully');
    });

    # if the result code was already set, we errored and rolled back the db..
    return if $c->res->code;

    $c->status(303, '/hardware_product/'.$hardware_product->id);
}

=head2 delete

=cut

sub delete ($c) {
    return $c->status(403) unless $c->is_system_admin;

    my $id = $c->stash('hardware_product_rs')->get_column('id')->single;
    $c->stash('hardware_product_rs')->deactivate;

    # delete the profile too, since they are 1:1.
    my $profile_rs = $c->stash('hardware_product_rs')->related_resultset('hardware_product_profile');
    my $hardware_product_profile_id = $profile_rs->get_column('id')->single;
    $profile_rs->deactivate;

    $c->log->debug('Deleted hardware product '.$id
        .($hardware_product_profile_id
            ? ' and its related hardware product profile id '.$hardware_product_profile_id : ''));
    return $c->status(204);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
