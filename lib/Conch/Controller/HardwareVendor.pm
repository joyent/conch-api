package Conch::Controller::HardwareVendor;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::User

=head1 METHODS

=head2 find_hardware_vendor

Handles looking up the object by id or name.

=cut

sub find_hardware_vendor ($c) {
    my $hardware_vendor_rs = $c->db_hardware_vendors->active;
    if (is_uuid($c->stash('hardware_vendor_id_or_name'))) {
        $c->log->debug('Looking up a hardware_vendor by id ('.$c->stash('hardware_vendor_id_or_name').')');
        $hardware_vendor_rs = $hardware_vendor_rs->search({ id => $c->stash('hardware_vendor_id_or_name') });
    }
    else {
        $c->log->debug('Looking up a hardware_vendor by name ('.$c->stash('hardware_vendor_id_or_name').')');
        $hardware_vendor_rs = $hardware_vendor_rs->search({ name => $c->stash('hardware_vendor_id_or_name') });
    }

    my $hardware_vendor = $hardware_vendor_rs->single;

    if (not $hardware_vendor) {
        $c->log->debug('Could not locate a valid hardware vendor');
        return $c->status(404);
    }

    $c->log->debug('Found hardware vendor '.$hardware_vendor->id);
    $c->stash('hardware_vendor', $hardware_vendor);
    return 1;
}

=head2 get_all

Retrieves all active hardware vendors.

Response uses the HardwareVendors json schema.

=cut

sub get_all ($c) {
    my @hardware_vendors = $c->db_hardware_vendors->active->all;
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
    return $c->status(403) unless $c->is_system_admin;

    if ($c->db_hardware_vendors->active->search({ name => $c->stash('hardware_vendor_name') }) > 0) {
        $c->log->debug('Failed to create hardware vendor: unique constraint violation for name');
        return $c->status(400, { error => 'Unique constraint violated on \'name\'' });
    }

    my $hardware_vendor = $c->db_hardware_vendors->create({ name => $c->stash('hardware_vendor_name') });

    $c->log->debug('Created hardware vendor '.$c->stash('hardware_vendor_name'));
    $c->status(303, '/hardware_vendor/'.$c->stash('hardware_vendor_name'));
}

=head2 delete

=cut

sub delete($c) {
    $c->log->debug('Deleting hardware vendor '.$c->stash('hardware_vendor')->id);
    $c->stash('hardware_vendor')->update({ deactivated => \'NOW()', updated => \'NOW()' });
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
