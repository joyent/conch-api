package Conch::Controller::WorkspaceDevice;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::WorkspaceDevice

=head1 METHODS

=head2 list

Get a list of all devices in the current workspace (as specified by :workspace_id in the path)

Supports these query parameters to constrain results (which are ANDed together, not ORed):

	graduated=T     only devices with graduated set
	graduated=F     only devices with graduated not set
	validated=T     only devices with validated set
	validated=F     only devices with validated not set
	health=<value>  only devices with health matching provided value (case-insensitive)
	active=1        only devices last seen within 5 minutes
	ids_only=1      only return device ids, not full data

Response uses the Devices json schema.

=cut

sub list ($c) {
	my $devices_rs = $c->stash('workspace_rs')
		->associated_racks
		->related_resultset('device_locations')
		->related_resultset('device')
		->active
		->order_by('device.created');

	$devices_rs = $devices_rs->search({ graduated => { '!=' => undef } })
		if defined $c->param('graduated') and uc $c->param('graduated') eq 'T';

	$devices_rs = $devices_rs->search({ graduated => undef })
		if defined $c->param('graduated') and uc $c->param('graduated') eq 'F';

	$devices_rs = $devices_rs->search({ validated => { '!=' => undef } })
		if defined $c->param('validated') and uc $c->param('validated') eq 'T';

	$devices_rs = $devices_rs->search({ validated => undef })
		if defined $c->param('validated') and uc $c->param('validated') eq 'F';

	$devices_rs = $devices_rs->search(\[ 'upper(health) = ?', uc $c->param('health') ])
		if defined $c->param('health');

	$devices_rs = $devices_rs->search({ last_seen => { '>' => \q{NOW() - interval '300 second'}} })
		if defined $c->param('active');

	$devices_rs = $devices_rs->get_column('id')
		if defined $c->param('ids_only');

	my @devices = $devices_rs->all;

	$c->status( 200, \@devices );
}

=head2 device_totals

Ported from 'conch-stats'.

Output conforms to the 'DeviceTotals' and 'DeviceTotalsCirconus' json schemas.
Add '.circ' to the end of the URL to select the data format customized for Circonus.

Note that this is an unauthenticated endpoint.

=cut

sub device_totals ($c) {
	my $workspace_param = $c->stash('workspace');

	my $workspace;
	if ( $workspace_param =~ /^name\=(.*)$/ ) {
		$workspace = $c->db_workspaces->find({ name => $1 }, { key => 'workspace_name_key' });
	}
	elsif ( is_uuid($workspace_param) ) {
		$workspace = $c->db_workspaces->find($workspace_param);
	}
	return $c->reply->not_found unless $workspace;

	my %switch_aliases = map { ( $_ => 1 ) } $c->config->{switch_aliases}->@*;
	my %storage_aliases = map { ( $_ => 1 ) } $c->config->{storage_aliases}->@*;
	my %compute_aliases = map { ( $_ => 1 ) } $c->config->{compute_aliases}->@*;

	my @counts = $workspace->self_rs
		->associated_racks
		->related_resultset('device_locations')
		->related_resultset('device')
		->active
		->search(
			{},
			{
				columns => { alias => 'hardware_product.alias', health => 'device.health' },
				select => [ { count => '*', -as => 'count' } ],
				group_by => [ 'hardware_product.alias', 'device.health' ],
				order_by => [ 'hardware_product.alias', 'device.health' ],
				join => 'hardware_product',
			},
		)->hri->all;

	my @switch_counts = grep { $switch_aliases{ $_->{alias} } } @counts;
	my @server_counts = grep { !$switch_aliases{ $_->{alias} } } @counts;
	my @storage_counts = grep { $storage_aliases{ $_->{alias} } } @counts;
	my @compute_counts = grep { $compute_aliases{ $_->{alias} } } @counts;

	my %circ;

	for (@storage_counts) {
		$circ{storage}{count} += $_->{count};
	}

	for (@compute_counts) {
		$circ{compute}{count} += $_->{count};
	}

	for (@counts) {
		if($circ{ $_->{alias}}) {
			$circ{ $_->{alias} }{count} += $_->{count};
			if( $circ{ $_->{alias} }{health}{ $_->{health} } ) {
				$circ{ $_->{alias} }{health}{ $_->{health} } += $_->{count};
			} else {
				$circ{ $_->{alias} }{health}{ $_->{health} } = $_->{count};
			}
		} else {
			$circ{ $_->{alias} } = {
				count => $_->{count},
				health => {
					FAIL => 0,
					PASS => 0,
					UNKNOWN => 0,
				}
			};
			$circ{ $_->{alias} }{health}{ $_->{health} } = $_->{count};
		}
	}

	return $c->respond_to(
		any => { json => {
			all      => \@counts,
			servers  => \@server_counts,
			switches => \@switch_counts,
			storage  => \@storage_counts,
			compute  => \@compute_counts,
		}},
		circ => { json => \%circ },
	);
};

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
