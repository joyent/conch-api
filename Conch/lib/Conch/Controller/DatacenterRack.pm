=pod

=head1 NAME

Conch::Controller::DatacenterRack

=head1 METHODS

=cut

package Conch::Controller::DatacenterRack;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;


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
		if($1 eq 'name') {
			$r = Conch::Model::DatacenterRack->from_name($2);
		} else {
			$c->status(404 => { error => "Not found" });
			return undef;
		}
	} else {
		$r = Conch::Model::DatacenterRack->from_id($c->param('id'));
	}

	if ($r) {
		$c->stash('rack' => $r);
		return 1;
	} else {
		$c->status(404 => { error => "Not found" });
		return undef;
	}
}

=head2 create

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $d = $c->validate_input('RackCreate') or return;

	unless(Conch::Model::DatacenterRoom->from_id($d->{datacenter_room_id})) {
		return $c->status(400 => { "error" => "Room does not exist" });
	}

	unless(Conch::Model::DatacenterRackRole->from_id($d->{role})) {
		return $c->status(400 => { "error" => "Rack role does not exist" });
	}
		
	my $r = Conch::Model::DatacenterRack->new($d->%*)->save();

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
	$c->status(200, Conch::Model::DatacenterRack->all());
}


=head2 update

=cut

sub update ($c) {
	my $i = $c->validate_input('RackUpdate') or return;

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
	return $c->status(303 => "/rack/".$c->stash('rack')->id);
}


=head2 delete

Delete a rack

=cut

sub delete ($c) {
	$c->stash('rack')->burn;
	return $c->status(204);
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

