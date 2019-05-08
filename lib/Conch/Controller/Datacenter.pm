package Conch::Controller::Datacenter;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::Datacenter

=head1 METHODS

=head2 find_datacenter

Handles looking up the object by id.

=cut

sub find_datacenter ($c) {
    return $c->status(403) if not $c->is_system_admin;

    my $datacenter_id = $c->stash('datacenter_id');
    my $datacenter = $c->db_datacenters->find($datacenter_id);

    if (not $datacenter) {
        $c->log->debug('Unable to find datacenter '.$datacenter_id);
        return $c->status(404);
    }

    $c->log->debug('Found datacenter '.$datacenter_id);
    $c->stash('datacenter', $datacenter);
    return 1;
}

=head2 get_all

Get all datacenters.

Response uses the Datacenters json schema.

=cut

sub get_all ($c) {
    return $c->status(403) if not $c->is_system_admin;

    my @datacenters = $c->db_datacenters->all;
    $c->log->debug('Found '.scalar(@datacenters).' datacenters');
    return $c->status(200, \@datacenters);
}

=head2 get_one

Get a single datacenter.

Response uses the Datacenter json schema.

=cut

sub get_one ($c) {
    return $c->status(403) if not $c->is_system_admin;
    $c->status(200, $c->stash('datacenter'));
}

=head2 get_rooms

Get all rooms for the given datacenter.

Response uses the DatacenterRoomsDetailed json schema.

=cut

sub get_rooms ($c) {
    return $c->status(403) if not $c->is_system_admin;

    my @rooms = $c->db_datacenter_rooms->search({ datacenter_id => $c->stash('datacenter')->id })->all;

    $c->log->debug('Found '.scalar(@rooms).' datacenter rooms');
    $c->status(200, \@rooms);
}

=head2 create

Create a new datacenter.

=cut

sub create ($c) {
    return $c->status(403) if not $c->is_system_admin;

    my $input = $c->validate_input('DatacenterCreate');
    return if not $input;

    my $datacenter = $c->db_datacenters->create($input);
    $c->log->debug('Created datacenter '.$datacenter->id);
    $c->status(303, '/dc/'.$datacenter->id);
}

=head2 update

Update an existing datacenter.

=cut

sub update ($c) {
    return $c->status(403) if not $c->is_system_admin;

    my $input = $c->validate_input('DatacenterUpdate');
    return if not $input;

    my $datacenter = $c->stash('datacenter');
    $datacenter->set_columns($input);
    $datacenter->update({ updated => \'now()' }) if $datacenter->is_changed;

    $c->log->debug('Updated datacenter '.$datacenter->id);
    $c->status(303, '/dc/'.$datacenter->id);
}

=head2 delete

Permanently delete a datacenter.

=cut

sub delete ($c) {
    return $c->status(403) if not $c->is_system_admin;

    if ($c->stash('datacenter')->related_resultset('datacenter_rooms')->exists) {
        $c->log->debug('Cannot delete datacenter: in use by one or more datacenter_rooms');
        return $c->status(400, { error => 'cannot delete a datacenter when a datacenter_room is referencing it' });
    }

    $c->stash('datacenter')->delete;
    $c->log->debug('Deleted datacenter '.$c->stash('datacenter')->id);
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
