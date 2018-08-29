package Conch::Controller::Datacenter;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

with 'Conch::Role::MojoLog';

use Conch::Models;

=head2 find_datacenter

Handles looking up the object by id or name depending on the url pattern

=cut

sub find_datacenter ($c) {
	unless($c->is_global_admin) {
		$c->status(403);
		return undef;
	}

	my $s;

	if($c->stash('datacenter_id') =~ /^(.+?)\=(.+)$/) {
		$c->status('501');
		return undef;
	} else {
		$s = Conch::Model::Datacenter->from_id($c->stash('datacenter_id'));
	}

	if ($s) {
		$c->log->debug("Found datacenter ".$c->stash('datacenter_id'));
		$c->stash('datacenter' => $s);
		return 1;
	} else {
		$c->log->debug("Unable to find datacenter ".$c->stash('datacenter_id'));
		$c->status(404 => { error => "Not found" });
		return undef;
	}

}


=head2 get_all

Get all datacenters

=cut

sub get_all ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my @dc = Conch::Model::Datacenter->all()->@*;

	$c->log->debug("Found ".scalar(@dc)." datacenters");

	return $c->status(200, \@dc);
}


=head2 get_one

Get a single datacenter

=cut

sub get_one ($c) {
	return $c->status(403) unless $c->is_global_admin;
	$c->status(200, $c->stash('datacenter'));
}



=head2 get_rooms

Get all rooms for the given datacenter

=cut

sub get_rooms ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my @rooms = $c->db_datacenter_rooms->search({ datacenter_id => $c->stash('datacenter')->id })->all;

	$c->log->debug("Found ".scalar(@rooms)." datacenter rooms");
	$c->status(200, \@rooms);
}

=head2 create

Create a new datacenter

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $i = $c->validate_input('DatacenterCreate');
	if(not $i) {
		$c->log->debug("Input failed validation");
		return;
	}	

	my $r = Conch::Model::Datacenter->new($i->%*)->save;
	$c->log->debug("Created datacenter ".$r->id);
	$c->status(303 => "/dc/".$r->id);
}


=head2 update

Update an existing datacenter

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $i = $c->validate_input('DatacenterUpdate');
	if(not $i) {
		$c->log->debug("Input failed validation");
		return;
	}

	$c->stash('datacenter')->update($i->%*)->save();
	$c->log->debug("Updated datacenter ".$c->stash('datacenter')->id);
	$c->status(303 => "/dc/".$c->stash('datacenter')->id);
}


=head2 delete

Permanently delete a datacenter

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_global_admin;
	$c->stash('datacenter')->burn;
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
