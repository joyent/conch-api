=pod

=head1 NAME

Conch::Controller::Relay

=head1 METHODS

=cut

package Conch::Controller::Relay;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;

=head2 register

Registers a relay and connects it with the current user. The relay is created
it if the relay does not already exists

=cut

sub register ($c) {
	my $body    = $c->req->json;
	my $user_id = $c->stash('user_id');
	my $serial  = $body->{serial};

	return $c->status( 400,
		{ error => "'serial' attribute required in request" } )
		unless defined($serial);

	Conch::Model::Relay->new->register(
		$serial,           $body->{version}, $body->{ipaddr},
		$body->{ssh_port}, $body->{alias},
	);

	my $attempt = Conch::Model::Relay->new->connect_user_relay(
		$user_id,
		$serial
	);

	unless ($attempt) {
		return $c->status( 500, { error => "unable to register relay '$serial'" } );
	}

	$c->status(204);
}

=head2 list

If the user is a global admin, retrieve a list of all relays in the database

=cut

sub list ($c) {
	return $c->status(403) unless $c->is_global_admin;
	$c->status(
		200,
		Conch::Model::Relay->new->list
	);
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
