=pod

=head1 NAME

Conch::Controller::DatacenterRack

=head1 METHODS

=cut

package Conch::Controller::DatacenterRack;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

with 'Conch::Role::MojoLog';


=head2 find_rack

Supports rack lookups by uuid and name

=cut

sub find_rack ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my $rack;

	if ($c->stash('datacenter_rack_id_or_name') =~ /^(.+?)\=(.+)$/) {
		my $key = $1;
		my $value = $2;

		if ($key eq 'name') {
			$c->log->debug("Looking up a datacenter rack by name $key");
			$rack = $c->db_datacenter_racks->find({ name => $value });
		} else {
			$c->log->warn("Unsupported identifier '$key' found");
			return $c->status(404 => { error => "Not found" });
		}
	} else {
		$c->log->debug('Looking for datacenter rack by id: '.$c->stash('datacenter_rack_id_or_name'));
		$rack = $c->db_datacenter_racks->find($c->stash('datacenter_rack_id_or_name'));
	}

	if (not $rack) {
		$c->log->debug('Could not find datacenter rack');
		return $c->status(404 => { error => 'Not found' });
	}

	$c->log->debug("Found datacenter rack ".$rack->id);
	$c->stash('rack' => $rack);
	return 1;
}

=head2 create

Stores data as a new datacenter_rack row, munging 'role' to 'datacenter_rack_role_id'.

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_system_admin;
	my $input = $c->validate_input('RackCreate');
	if (not $input) {
		$c->log->debug("Input failed validation");
		return $c->status(400);
	}

	unless ($c->db_datacenter_rooms->search({ id => $input->{datacenter_room_id} })->count) {
		return $c->status(400 => { "error" => "Room does not exist" });
	}

	unless ($c->db_datacenter_rack_roles->search({ id => $input->{role} })->count) {
		return $c->status(400 => { "error" => "Rack role does not exist" });
	}

	$input->{datacenter_rack_role_id} = delete $input->{role};

	my $rack = $c->db_datacenter_racks->create($input);
	$c->log->debug("Created datacenter rack ".$rack->id);

	$c->status(303 => "/rack/".$rack->id);
}

=head2 get

Get a single rack

=cut

sub get ($c) {
	$c->status(200, $c->stash('rack'));
}



=head2 get_all

Get all racks

=cut

sub get_all ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my @racks = $c->db_datacenter_racks->all;
	$c->log->debug('Found '.scalar(@racks).' datacenter racks');

	$c->status(200, \@racks);
}

=head2 layouts

=cut

sub layouts ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my @layouts = $c->db_datacenter_rack_layouts->search({ rack_id => $c->stash('rack')->id });

	$c->log->debug('Found '.scalar(@layouts).' datacenter rack layouts');
	$c->status(200 => \@layouts);
}



=head2 update

=cut

sub update ($c) {
	my $input = $c->validate_input('RackUpdate');
	if (not $input) {
		$c->log->debug("Input failed validation");
		return;
	}

	if ($input->{datacenter_room_id}) {
		unless ($c->db_datacenter_rooms->search({ id => $input->{datacenter_room_id} })->count) {
			return $c->status(400 => { "error" => "Room does not exist" });
		}
	}

	if (exists $input->{role}) {
		if ($c->db_datacenter_rack_roles->search({ id => $input->{role} })->count) {
			$input->{datacenter_rack_role_id} = delete $input->{role};
		} else {
			return $c->status(400 => { "error" => "Rack role does not exist" });
		}
	}

	$c->stash('rack')->update($input);
	$c->log->debug("Updated datacenter rack ".$c->stash('rack')->id);
	return $c->status(303 => "/rack/".$c->stash('rack')->id);
}


=head2 delete

Delete a rack

=cut

sub delete ($c) {
	$c->stash('rack')->delete;
	$c->log->debug("Deleted datacenter rack ".$c->stash('rack')->id);
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
