=pod

=head1 NAME

Conch::Controller::DatacenterRackRole

=head1 METHODS

=cut

package Conch::Controller::DatacenterRackRole;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;

with 'Conch::Role::MojoLog';


=head2 under

Supports rack role lookups by uuid and name

=cut

sub under ($c) {
	unless($c->is_global_admin) {
		$c->status(403);
		return undef;
	}

	my $r;

	if($c->param('id') =~ /^(.+?)\=(.+)$/) {
		my ($k, $v) = ($1, $2);
		if($k eq 'name') {
			$c->log->debug("Looking up datacenter rack role using identifier '$k'");
			$r = Conch::Model::DatacenterRackRole->from_name($v);
		} else {
			$c->log->warn("Unknown identifier '$k'");
			$c->status(404 => { error => "Not found" });
			return undef;
		}
	} else {
		$c->log->debug("looking up datacenter rack role by id");
		$r = Conch::Model::DatacenterRackRole->from_id($c->param('id'));
	}

	if ($r) {
		$c->log->debug("Found datacenter rack role ".$r->id);
		$c->stash('rack_role' => $r);
		return 1;
	} else {
		$c->log->debug("Failed to find datacenter rack role");
		$c->status(404 => { error => "Not found" });
		return undef;
	}
}

=head2 create

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $d = $c->validate_input('RackRoleCreate');
	if(not $d) {
		$c->log->warn("Input failed validation");
		return;
	}

	if(Conch::Model::DatacenterRackRole->from_name($d->{name})) {
		$c->log->debug("Name conflict on '".$d->{name}."'");
		return $c->status(400 => { error => "name is already taken" });
	}

	my $r = Conch::Model::DatacenterRackRole->new($d->%*)->save();
	$c->log->debug("Created datacenter rack role ".$r->id);
	$c->status(303 => "/rack_role/".$r->id);
}

=head2 get

Get a single rack role

=cut

sub get ($c) {
	return $c->status(403) unless $c->is_global_admin;
	$c->status(200, $c->stash('rack_role'));
}



=head2 get_all

Get all rack roles

=cut

sub get_all ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $r = Conch::Model::DatacenterRackRole->all();
	$c->log->debug("Found ".scalar($r->@*)." datacenter rack roles");

	$c->status(200 => $r);
}


=head2 update

=cut


sub update ($c) {
	my $i = $c->validate_input('RackRoleUpdate');
	if(not $i) {
		$c->log->warn("Input failed validation");
		return;
	}

	if ($i->{name}) {
		if(Conch::Model::DatacenterRackRole->from_name($i->{name})) {
			$c->log->debug("Name conflict on '".$i->{name}."'");
			return $c->status(400 => { error => "name is already taken" });
		}
	}
	$c->stash('rack_role')->update($i->%*)->save();
	$c->log->debug("Updated datacenter rack role ".$c->stash('rack_role')->id);
	$c->status(303 => "/rack_role/".$c->stash('rack_role')->id);
}


=head2 delete

Delete a rack role

=cut

sub delete ($c) {
	$c->stash('rack_role')->burn;
	$c->log->debug("Deleted datacenter rack role ".$c->stash('rack_role')->id);
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
