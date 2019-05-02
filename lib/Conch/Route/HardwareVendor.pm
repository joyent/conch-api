package Conch::Route::HardwareVendor;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::HardwareVendor

=head1 METHODS

=head2 routes

Sets up the routes for /hardware_vendor:

    GET     /hardware_vendor
    GET     /hardware_vendor/:hardware_vendor_id_or_name
    POST    /hardware_vendor/:hardware_vendor_name
    DELETE  /hardware_vendor/:hardware_vendor_id_or_name

=cut

sub routes {
    my $class = shift;
    my $hv = shift;     # secured, under /hardware_vendor

    $hv->to({ controller => 'hardware_vendor' });

    # GET /hardware_vendor
    $hv->get('/')->to('#get_all');

    {
        my $with_hv = $hv->under('/:hardware_vendor_id_or_name')
            ->to('#find_hardware_vendor');

        # GET /hardware_vendor/:hardware_vendor_id_or_name
        $with_hv->get('/')->to('#get_one');

        # DELETE /hardware_vendor/:hardware_vendor_id_or_name
        $with_hv->delete('/')->to('#delete');
    }

    # POST /hardware_vendor/:hardware_vendor_name
    $hv->post('/:hardware_vendor_name')->to('#create');
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
