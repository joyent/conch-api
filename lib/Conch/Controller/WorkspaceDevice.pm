=pod

=head1 NAME

Conch::Controller::WorkspaceDevice

=head1 METHODS

=cut

package Conch::Controller::WorkspaceDevice;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

with 'Conch::Role::MojoLog';

=head2 list

Get a list of all devices in the current workspace (as specified by :workspace_id in the path)

Supports these query parameters to constrain results:

	graduated=T     only devices with graduated set
	graduated=F     only devices with graduated not set
	health=<value>  only devices with health matching provided value (case-insensitive)
	active=1        only devices last seen within 5 minutes
	ids_only=1      only return device ids, not full data

=cut

sub list ($c) {
	my $devices_rs = $c->stash('workspace_rs')
		->associated_racks
		->related_resultset('device_locations')
		->related_resultset('device')
		->active;

	$devices_rs = $devices_rs->search({ graduated => { '!=' => undef } })
		if defined $c->param('graduated') and uc $c->param('graduated') eq 'T';

	$devices_rs = $devices_rs->search({ graduated => undef })
		if defined $c->param('graduated') and uc $c->param('graduated') eq 'F';

	$devices_rs = $devices_rs->search(\[ 'upper(health) = ?', uc $c->param('health') ])
		if defined $c->param('health');

	$devices_rs = $devices_rs->search({ last_seen => { '>' => \q{NOW() - interval '300 second'}} })
		if defined $c->param('active');

	$devices_rs = $devices_rs->get_column('id')
		if defined $c->param('ids_only');

	my @devices = $devices_rs->all;

	$c->status( 200, \@devices );
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
