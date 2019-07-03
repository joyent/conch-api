package Conch::Controller::Relay;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::Relay

=head1 METHODS

=head2 register

Registers a relay and connects it with the current user. The relay is created if the relay does
not already exist, or is updated with additional payload information otherwise.

=cut

sub register ($c) {
    my $input = $c->validate_request('RegisterRelay');
    return if not $input;

    return $c->status(400, { error => 'serial number in path doesn\'t match payload data' })
        if $c->stash('relay_serial_number') ne $input->{serial};

    my $relay = $c->db_relays->find_or_new({ serial_number => delete $input->{serial} });
    $relay->set_columns({ $input->%*, deactivated => undef });

    if (not $relay->in_storage) {
        $relay->insert;
        $c->status(201);
    }
    else {
        $relay->update({ updated => \'now()' }) if $relay->is_changed;
        $c->status(204);
    }

    $relay->update_or_create_related('user_relay_connections', {
        user_id => $c->stash('user_id'),
        last_seen => \'now()',
    });

    $c->res->headers->location($c->url_for('/relay/'.$relay->id));
    return;
}

=head2 list

If the user is a system admin, retrieve a list of all active relays in the database.
Requires the user to be a system admin.

Response uses the Relays json schema.

=cut

sub list ($c) {
    return $c->status(403) if not $c->is_system_admin;
    $c->status(200, [ $c->db_relays->active->order_by('serial_number')->all ]);
}

=head2 get

Get the details of a single relay.
Requires the user to be a system admin, or have previously registered the relay.

Response uses the Relay json schema.

=cut

sub get ($c) {
    my $identifier = $c->stash('relay_id_or_serial_number');

    my $rs = $c->db_relays
        ->active
        ->search({ is_uuid($identifier) ? 'id' : 'serial_number' => $identifier });

    return $c->status(404) if not $rs->exists;

    $rs = $rs->search({ user_id => $c->stash('user_id') }, { join => 'user_relay_connections' })
        if not $c->is_system_admin;

    my $relay = $rs->single;
    return $c->status(403) if not $relay;
    $c->status(200, $relay);
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
