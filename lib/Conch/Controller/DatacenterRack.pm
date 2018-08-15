=pod

=head1 NAME

Conch::Controller::DatacenterRack

=head1 METHODS

=cut

package Conch::Controller::DatacenterRack;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;

with 'Conch::Role::MojoLog';


=head2 under

Supports rack lookups by uuid and name

=cut

sub under ($c) {
	unless($c->is_global_admin) {
		$c->status(403);
		return undef;
	}

	my $r;

	if($c->param('id') =~ /^(.+?)\=(.+)$/) {
		my $k = $1;
		my $v = $2;

		if($k eq 'name') {
			$c->log->debug("Looking up a datacenter rack by identifier $k");
			$r = Conch::Model::DatacenterRack->from_name($v);
		} else {
			$c->log->warn("Unsupported identifier '$k' found");
			$c->status(404 => { error => "Not found" });
			return undef;
		}
	} else {
		$c->log->debug("Looking for datacenter rack ".$c->param('id'));
		$r = Conch::Model::DatacenterRack->from_id($c->param('id'));
	}

	if ($r) {
		$c->log->debug("Found datacenter rack ".$r->id);
		$c->stash('rack' => $r);
		return 1;
	} else {
		$c->log->debug("Could not find datacenter rack"); 
		$c->status(404 => { error => "Not found" });
		return undef;
	}
}

=head2 create

Stores data as a new datacenter_rack row, munging 'role' to 'datacenter_rack_role_id'.

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $d = $c->validate_input('RackCreate');
	if(not $d) {
		$c->log->debug("Input failed validation");
		return;
	}

	unless(Conch::Model::DatacenterRoom->from_id($d->{datacenter_room_id})) {
		return $c->status(400 => { "error" => "Room does not exist" });
	}

	unless(Conch::Model::DatacenterRackRole->from_id($d->{role})) {
		return $c->status(400 => { "error" => "Rack role does not exist" });
	}

	my %data = $d->%*;
	$data{datacenter_rack_role_id} = delete $data{role};

	my $r = Conch::Model::DatacenterRack->new(%data)->save();
	$c->log->debug("Created datacenter rack ".$r->id);

	$c->status(303 => "/rack/".$r->id);

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
	return $c->status(403) unless $c->is_global_admin;

	my $r = Conch::Model::DatacenterRack->all();
	$c->log->debug("Found ".scalar($r->@*)." datacenter racks");

	$c->status(200, $r);
}

=head2 layouts

=cut

sub layouts ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $l = Conch::Model::DatacenterRackLayout->from_rack_id(
		$c->stash('rack')->id
	);

	$c->log->debug("Found ".scalar($l->@*)." datacenter rack layouts");
	$c->status(200 => $l);
}



=head2 update

=cut

sub update ($c) {
	my $i = $c->validate_input('RackUpdate');
	if(not $i) {
		$c->log->debug("Input failed validation");
		return;
	}

	if($i->{datacenter_room_id}) {
		unless(Conch::Model::DatacenterRoom->from_id($i->{datacenter_room_id})) {
			return $c->status(400 => { "error" => "Room does not exist" });
		}
	}

	if($i->{role}) {
		unless(Conch::Model::DatacenterRackRole->from_id($i->{role})) {
			return $c->status(400 => { "error" => "Rack role does not exist" });
		}
	}

	$c->stash('rack')->update($i->%*)->save();
	$c->log->debug("Updated datacenter rack ".$c->stash('rack')->id);
	return $c->status(303 => "/rack/".$c->stash('rack')->id);
}


=head2 delete

Delete a rack

=cut

sub delete ($c) {
	$c->stash('rack')->burn;
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
