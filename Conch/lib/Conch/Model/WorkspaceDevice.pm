=pod

=head1 NAME

Conch::Model::WorkspaceDevice

=head1 METHODS

=cut
package Conch::Model::WorkspaceDevice;
use Mojo::Base -base, -signatures;

use Conch::Model::Device;

use Conch::Pg;

=head2 list

List all devices located in workspace.

=cut
sub list ( $self, $ws_id, $last_seen_seconds = undef ) {
	my $last_seen_clause =
		$last_seen_seconds
		? "WHERE last_seen > NOW() - ? * interval '1 second'"
		: '';

	my $ret = Conch::Pg->new->db->query(
		qq{
		select * from workspace_devices(?)
  		$last_seen_clause
	}, ($ws_id, $last_seen_seconds || () )
	)->hashes;

	my @devices;
	for my $d ( $ret->@* ) {
		push @devices, Conch::Model::Device->new(%$d);
	}
	return \@devices;
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

