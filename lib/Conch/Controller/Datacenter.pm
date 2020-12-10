package Conch::Controller::Datacenter;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::Datacenter

=head1 METHODS

=head2 find_datacenter

Chainable action that uses the C<datacenter_id> value provided in the stash (usually via the
request URL) to look up a datacenter, and stashes the result in C<datacenter>.

=cut

sub find_datacenter ($c) {
    my $datacenter_id = $c->stash('datacenter_id');
    my $datacenter = $c->db_datacenters->find($datacenter_id);

    if (not $datacenter) {
        $c->log->debug('Could not find datacenter '.$datacenter_id);
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
    my @datacenters = $c->db_datacenters
        ->order_by([ qw(vendor region location) ])
        ->all;
    $c->log->debug('Found '.scalar(@datacenters).' datacenters');
    return $c->status(200, \@datacenters);
}

=head2 get_one

Get a single datacenter.

Response uses the Datacenter json schema.

=cut

sub get_one ($c) {
    $c->status(200, $c->stash('datacenter'));
}

=head2 get_rooms

Get all rooms for the given datacenter.

Response uses the DatacenterRoomsDetailed json schema.

=cut

sub get_rooms ($c) {
    my @rooms = $c->db_datacenter_rooms->search({ datacenter_id => $c->stash('datacenter')->id })->all;

    $c->log->debug('Found '.scalar(@rooms).' datacenter rooms');
    $c->status(200, \@rooms);
}

=head2 create

Create a new datacenter.

=cut

sub create ($c) {
    my $input = $c->stash('request_data');

    if (my $dc = $c->db_datacenters->find({ $input->%{qw(vendor region location)} })) {
        $dc->set_columns({ $input->%{vendor_name} });   # set all columns not used in the unique key
        if ($dc->is_changed) {
            return $c->status(409, { error => 'a datacenter already exists with that vendor-region-location' });
        }
        else {
            return $c->status(204, '/dc/'.$dc->id);
        }
    }

    my $dc = $c->db_datacenters->create($input);
    $c->log->debug('Created datacenter '.$dc->id);
    $c->res->headers->location('/dc/'.$dc->id);
    $c->status(201);
}

=head2 update

Update an existing datacenter.

=cut

sub update ($c) {
    my $input = $c->stash('request_data');
    my $datacenter = $c->stash('datacenter');
    $datacenter->set_columns($input);
    return $c->status(204, '/dc/'.$datacenter->id) if not $datacenter->is_changed;

    $datacenter->update({ updated => \'now()' });
    $c->log->debug('Updated datacenter '.$datacenter->id);
    $c->status(204, '/dc/'.$datacenter->id);
}

=head2 delete

Permanently delete a datacenter.

=cut

sub delete ($c) {
    if ($c->stash('datacenter')->related_resultset('datacenter_rooms')->exists) {
        $c->log->debug('Cannot delete datacenter: in use by one or more datacenter_rooms');
        return $c->status(409, { error => 'cannot delete a datacenter when a datacenter_room is referencing it' });
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
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
