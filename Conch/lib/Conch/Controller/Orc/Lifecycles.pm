=head1 NAME

Conch::Controller::Orc::Lifecycles

=head1 METHODS

=cut

package Conch::Controller::Orc::Lifecycles;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Orc;

=head2 get_all

Get all Lifecycles. 

=cut

sub get_all ($c) {
	my $many = Conch::Orc::Lifecycle->all();
	$c->status(200, [ map { $_->serialize } $many->@* ]);
}



=head2 get_one

Get a single Lifecycle by UUID

=cut

sub get_one ($c) {
	my $l = Conch::Orc::Lifecycle->from_id($c->param('id'));
	$c->status(404 => { error => "Not found" }) unless $l;

	$c->status(200, $l->serialize);
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

