package Conch::Controller::HardwareProduct;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::HardwareProduct

=head1 METHODS

=head2 list

Get a list of all available hardware products.

Response uses the HardwareProducts json schema.

TODO: fold together with GET /db/hardware_product

=cut

sub list ($c) {

    my @hardware_products_raw = map {
        my $raw = $_->TO_JSON;
        delete $raw->@{qw(created updated)};    # db endpoints want these fields, we don't

        # the /db endpoint doesn't want profile serialized too, so we have to do it here.
        $raw->{profile} = $_->hardware_product_profile->TO_JSON if $_->hardware_product_profile;

        $raw;
    } $c->db_hardware_products->active->search(
        {
            # FIXME: do we really want no results if there are no associated vendors or profiles?
            hardware_vendor_id => { '!=' => undef },
            'hardware_product_profile.hardware_product_id' => { '!=' => undef },
        },
        { prefetch => { 'hardware_product_profile' => 'zpool_profile' } },
    )->all;

    $c->status( 200, \@hardware_products_raw);
}


=head2 get

Get the details of a single hardware product, given a valid UUID

Response uses the HardwareProduct json schema.

TODO: fold together with GET /db/hardware_product/:hardware_product_id

=cut

sub get ($c) {
    my $hw_id = $c->stash('hardware_product_id');

    return $c->status( 400,
        { error => "Hardware Product ID must be a UUID. Got '$hw_id'." } )
        unless is_uuid($hw_id);

    my $hardware_product = $c->db_hardware_products->active->search(
        {
            'hardware_product.id' => $hw_id,
            # FIXME: do we really want no results if there are no associated vendors or profiles?
            'hardware_product.hardware_vendor_id' => { '!=' => undef },
            'hardware_product_profile.hardware_product_id' => { '!=' => undef },
        },
        { prefetch => { 'hardware_product_profile' => 'zpool_profile' } },
    )->single;

    my $raw;
    if ($hardware_product) {
        $raw = $hardware_product->TO_JSON;
        delete $raw->@{qw(created updated)};    # db endpoints want these fields, we don't
        # the db endpoint doesn't want profile serialized too, so we have to do it here.
        $raw->{profile} = $hardware_product->hardware_product_profile->TO_JSON;
    };

    return $c->status(404, { error => "Hardware Product $hw_id not found" })
        if not $hardware_product;

    return $c->status(200, $raw);
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
