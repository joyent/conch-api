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
    my $input = $c->stash('request_data');

    return $c->status(400, { error => 'serial number in path doesn\'t match payload data' })
        if $c->stash('relay_serial_number') ne $input->{serial};

    my $relay = $c->db_relays->find_or_new({ serial_number => delete $input->{serial} });
    $relay->set_columns({
        $input->%*,
        user_id => $c->stash('user_id'),
        deactivated => undef,
    });

    if (not $relay->in_storage) {
        $relay->insert;
        $c->status(201);
    }
    else {
        $relay->updated(\'now()') if $relay->is_changed;
        $relay->update({ last_seen => \'now()' });
        $c->status(204);
    }

    $c->res->headers->location($c->url_for('/relay/'.$relay->id));
    return;
}

=head2 get_all

Retrieve a list of all active relays in the database.

Response uses the Relays json schema.

=cut

sub get_all ($c) {
    $c->status(200, [ $c->db_relays->active->order_by('serial_number')->all ]);
}

=head2 find_relay

Chainable action that uses the C<relay_id_or_serial_number> provided in the stash (usually
via the request URL), and stashes the query to get to it in C<relay_rs>.

The relay must have been registered by the user to continue; otherwise the user must be a
system admin.

=cut

sub find_relay ($c) {
    my $identifier = $c->stash('relay_id_or_serial_number');

    my $rs = $c->db_relays
        ->search({ is_uuid($identifier) ? 'id' : 'serial_number' => $identifier });
    if (not $rs->exists) {
        $c->log->debug('Could not find relay '.$identifier);
        return $c->status(404);
    }

    $rs = $rs->active;
    return $c->status(410) if not $rs->exists;

    if (not $c->is_system_admin) {
        if (not $rs->search({ user_id => $c->stash('user_id') })->exists) {
            $c->log->debug('User cannot access unregistered relay '.$identifier);
            return $c->status(403);
        }
    }

    $c->stash('relay_rs', $rs);
    return 1;
}

=head2 get

Get the details of a single relay.
Requires the user to be a system admin, or have previously registered the relay.

Response uses the Relay json schema.

=cut

sub get ($c) {
    $c->status(200, $c->stash('relay_rs')->single);
}

=head2 delete

=cut

sub delete ($c) {
    my $rs = $c->stash('relay_rs');

    my $drc_count = $rs->related_resultset('device_relay_connections')->delete;
    $rs->deactivate;

    $c->log->debug('Deactivated relay '.$c->stash('relay_id_or_serial_number')
        .', removing '.$drc_count.' associated device connections');
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
