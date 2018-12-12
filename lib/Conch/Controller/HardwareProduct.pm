package Conch::Controller::HardwareProduct;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use List::Util 'none';
use Conch::UUID 'is_uuid';

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
        ->prefetch({ 'hardware_product_profile' => 'zpool_profile' })
        ->all;

    $c->status( 200, \@hardware_products_raw);
}

=head2 find_hardware_product

Chainable action that looks up the object by id or sku depending on the url pattern,
stashing the query to get to it in C<hardware_product_rs>.

=cut

sub find_hardware_product ($c) {
    my $hardware_product_rs = $c->db_hardware_products->active;

    my ($key, $value) = split(/=/, $c->stash('hardware_product_id'), 2);
    if ($key and $value) {
        if (none { $key eq $_ } qw(sku name alias)) {
            $c->log->debug("Unknown identifier '$key' passed to HardwareProduct lookup");
            return $c->status('501');
        }

        $c->log->debug("Looking up a HardwareProduct by identifier ($key = $value)");
        $hardware_product_rs = $hardware_product_rs
            ->search({ "hardware_product.$key" => $value });
    } else {
        $c->log->debug("Looking up a HardwareProduct by id ".$c->stash('hardware_product_id'));
        return $c->status(404 => { error => 'Not found' }) if not is_uuid($c->stash('hardware_product_id'));
        $hardware_product_rs = $hardware_product_rs
            ->search({ 'hardware_product.id' => $c->stash('hardware_product_id') });
    }

    if (not $hardware_product_rs->exists) {
        $c->log->debug('Could not locate a valid hardware product');
        return $c->status(404 => { error => 'Not found' });
    }

    $c->stash('hardware_product_rs' => scalar $hardware_product_rs);
    return 1;
}

=head2 get

Get the details of a single hardware product.

Response uses the HardwareProduct json schema.

=cut

sub get ($c) {
    my $rs = $c->stash('hardware_product_rs')
        ->prefetch({ 'hardware_product_profile' => 'zpool_profile' });

    $c->status(200 => $rs->single);
}

=head2 create

Creates a new hardware_product, and possibly also a hardware_product_profile and zpool_profile.

Missing zpool_profile fields will default to null when creating new rows, but if an existing
row can be matched up to the fields provided, that entry will be re-used rather than creating a
new one.

=cut

sub create ($c) {
    return $c->status(403) unless $c->is_system_admin;

    my $input = $c->validate_input('HardwareProductCreate');
    return if not $input;

    for my $key (qw(name alias sku)) {
        next unless $input->{$key};
        if ($c->db_hardware_products->active->search({ $key => $input->{$key} })->exists) {
            $c->log->debug("Failed to create hardware product: unique constraint violation for $key");
            return $c->status(400 => {
                error => "Unique constraint violated on '$key'"
            });
        }
    }

    # backcompat only
    $input->{hardware_vendor_id} = delete $input->{vendor} if exists $input->{vendor};

    # create profiles and/or zpool entries as well, as needed.
    # Note that if a zpool already exists and can be uniquely identified without conflict, its
    # id is used instead of creating a new entry!
    my $hardware_product = $c->txn_wrapper(sub ($c) {
        $c->db_hardware_products->create($input);
    });

    # if the result code was already set, we errored and rolled back the db..
    return if $c->res->code;

    $c->log->debug('Created hardware product id '.$hardware_product->id.
        ($input->{hardware_product_profile}
          ? (' and hardware product profile id '.$hardware_product->hardware_product_profile->id .
            ($input->{hardware_product_profile}{zpool_profile}
              ? (' and zpool profile id '.$hardware_product->hardware_product_profile->zpool_id)
              : ''))
          : '')
    );
    $c->status(303 => "/hardware_product/".$hardware_product->id);
}

=head2 update

Updates an existing hardware_product, possibly updating or creating a hardware_product_profile
and zpool_profile as needed.

=cut

sub update ($c) {
    return $c->status(403) unless $c->is_system_admin;

    my $input = $c->validate_input('HardwareProductUpdate');
    return if not $input;

    my $hardware_product = $c->stash('hardware_product_rs')
        ->prefetch('hardware_product_profile')
        ->single;

    if ($hardware_product->id ne delete $input->{id}) {
        $c->log->debug('hardware product identified by the path does not match the id in the payload.');
        return $c->status(400 => { error => 'mismatch between path and payload' });
    }

    for my $key (qw(name alias sku)) {
        next unless defined $input->{$key};
        next if $input->{$key} eq $hardware_product->$key;

        if ($c->db_hardware_products->active->search({ $key => $input->{$key} })->exists) {
            $c->log->debug("Failed to create hardware product: unique constraint violation for $key");
            return $c->status(400 => { error => "Unique constraint violated on '$key'" });
        }
    }

    # backcompat only
    $input->{hardware_vendor_id} = delete $input->{vendor} if exists $input->{vendor};

    $c->txn_wrapper(sub ($c) {
        $c->log->debug('start of transaction...');

        my $profile = delete $input->{hardware_product_profile};
        if ($profile and keys %$profile) {

            # we don't really need to do this check, as the db will check the foreign key
            # constraint for us, die and force a rollback, but let's be nice...
            if ($profile->{zpool_id}
                    and not $c->db_zpool_profiles->active
                        ->search({ id => $profile->{zpool_id} })->exists) {
                $c->log->debug("Failed to update hardware product: zpool_id $profile->{zpool_id} does not exist");
                $c->status(400 => { error => "zpool_id $profile->{zpool_id} does not exist" });
                die 'rollback';
            }

            if (my $zpool = delete $profile->{zpool_profile}) {
                # we don't update existing zpools because other profiles could be using it.
                # Instead, we attempt to create a new one -- which is ok as long as there
                # is no name conflict.
                my $zpool_profile = $c->db_zpool_profiles->find_or_create($zpool);
                $profile->{zpool_id} = $zpool_profile->id;
                $c->log->debug('Assigned zpool_profile id '.$zpool_profile->id.'to hardware_product_profile for hardware product '.$hardware_product->id);
            }

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

                    $hardware_product->create_related('hardware_product_profile' => $profile);
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

    $c->status(303 => '/hardware_product/'.$hardware_product->id);
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

    $c->log->debug("Deleted hardware product $id"
        . ($hardware_product_profile_id
            ? " and its related hardware product profile id $hardware_product_profile_id" : ''));
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
