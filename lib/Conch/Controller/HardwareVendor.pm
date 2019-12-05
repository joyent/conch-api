package Conch::Controller::HardwareVendor;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::HardwareVendor

=head1 METHODS

=head2 find_hardware_vendor

Chainable action that uses the C<hardware_vendor_id_or_name> value provided in the stash
(usually via the request URL) to look up a build, and stashes the result in C<hardware_vendor>.

=cut

sub find_hardware_vendor ($c) {
    my $hardware_vendor_rs = $c->db_hardware_vendors;
    if (is_uuid($c->stash('hardware_vendor_id_or_name'))) {
        $c->log->debug('Looking up a hardware_vendor by id ('.$c->stash('hardware_vendor_id_or_name').')');
        $hardware_vendor_rs = $hardware_vendor_rs->search({ id => $c->stash('hardware_vendor_id_or_name') });
    }
    else {
        $c->log->debug('Looking up a hardware_vendor by name ('.$c->stash('hardware_vendor_id_or_name').')');
        $hardware_vendor_rs = $hardware_vendor_rs->search({ name => $c->stash('hardware_vendor_id_or_name') });
    }

    if (not $hardware_vendor_rs->exists) {
        $c->log->debug('Could not find hardware vendor '.$c->stash('hardware_vendor_id_or_name'));
        return $c->status(404);
    }

    my $hardware_vendor = $hardware_vendor_rs->active->single;
    return $c->status(410) if not $hardware_vendor;

    $c->log->debug('Found hardware vendor '.$hardware_vendor->id);
    $c->stash('hardware_vendor', $hardware_vendor);
    return 1;
}

=head2 get_all

Retrieves all active hardware vendors.

Response uses the HardwareVendors json schema.

=cut

sub get_all ($c) {
    my @hardware_vendors = $c->db_hardware_vendors->active->order_by('name')->all;
    $c->log->debug('Found '. (scalar @hardware_vendors) .' hardware vendors');
    return $c->status(200, \@hardware_vendors);
}

=head2 get_one

Gets one (active) hardware vendor.

Response uses the HardwareVendor json schema.

=cut

sub get_one ($c) {
    $c->status(200, $c->stash('hardware_vendor'));
}

=head2 create

=cut

sub create ($c) {
    $c->validate_request('Null');
    return if $c->res->code;

    if ($c->db_hardware_vendors->active->search({ name => $c->stash('hardware_vendor_name') }) > 0) {
        $c->log->debug('Failed to create hardware vendor: unique constraint violation for name');
        return $c->status(409, { error => 'Unique constraint violated on \'name\'' });
    }

    my $hardware_vendor = $c->db_hardware_vendors->create({ name => $c->stash('hardware_vendor_name') });

    $c->log->debug('Created hardware vendor '.$c->stash('hardware_vendor_name'));
    $c->status(303, '/hardware_vendor/'.$c->stash('hardware_vendor_name'));
}

=head2 delete

=cut

sub delete($c) {
    $c->log->debug('Deleting hardware vendor '.$c->stash('hardware_vendor')->id);
    $c->stash('hardware_vendor')->update({ deactivated => \'now()', updated => \'now()' });
    return $c->status(204);
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
