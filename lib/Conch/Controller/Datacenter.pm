package Conch::Controller::Datacenter;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

=pod

=head1 NAME

Conch::Controller::Datacenter

=head1 METHODS

=head2 find_datacenter

Handles looking up the object by id or name depending on the url pattern

=cut

sub find_datacenter ($c) {
	unless($c->is_system_admin) {
		$c->status(403);
		return undef;
	}

	if ($c->stash('datacenter_id') =~ /^(.+?)\=(.+)$/) {
		return $c->status('501');
	}

	my $datacenter = $c->db_datacenters->find($c->stash('datacenter_id'));

	if (not $datacenter) {
		$c->log->debug("Unable to find datacenter ".$c->stash('datacenter_id'));
		return $c->status(404 => { error => "Not found" });
	}

	$c->log->debug('Found datacenter '.$c->stash('datacenter_id'));
	$c->stash('datacenter' => $datacenter);
	return 1;
}


=head2 get_all

Get all datacenters

=cut

sub get_all ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my @datacenters = $c->db_datacenters->all;
	$c->log->debug("Found ".scalar(@datacenters)." datacenters");
	return $c->status(200, \@datacenters);
}


=head2 get_one

Get a single datacenter

=cut

sub get_one ($c) {
	return $c->status(403) unless $c->is_system_admin;
	$c->status(200, $c->stash('datacenter'));
}



=head2 get_rooms

Get all rooms for the given datacenter

Response matches the DatacenterRoomsDetailed json schema.

=cut

sub get_rooms ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my @rooms = $c->db_datacenter_rooms->search({ datacenter_id => $c->stash('datacenter')->id })->all;

	$c->log->debug("Found ".scalar(@rooms)." datacenter rooms");
	$c->status(200, \@rooms);
}

=head2 create

Create a new datacenter

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my $input = $c->validate_input('DatacenterCreate');
	return if not $input;

	my $datacenter = $c->db_datacenters->create($input);
	$c->log->debug("Created datacenter ".$datacenter->id);
	$c->status(303 => "/dc/".$datacenter->id);
}


=head2 update

Update an existing datacenter

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_system_admin;
	my $input = $c->validate_input('DatacenterUpdate');
	return if not $input;

	$c->stash('datacenter')->update($input);
	$c->log->debug("Updated datacenter ".$c->stash('datacenter')->id);
	$c->status(303 => "/dc/".$c->stash('datacenter')->id);
}


=head2 delete

Permanently delete a datacenter

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_system_admin;
	$c->stash('datacenter')->delete;
	$c->log->debug("Deleted datacenter ".$c->stash('datacenter')->id);
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
