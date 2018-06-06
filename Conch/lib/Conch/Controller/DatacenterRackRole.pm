=pod

=head1 NAME

Conch::Controller::DatacenterRackRole

=head1 METHODS

=cut

package Conch::Controller::DatacenterRackRole;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;


=head2 under

Supports rack role lookups by uuid and name

=cut

sub under ($c) {
	my $r;

	if($c->param('id') =~ /^(.+?)\=(.+)$/) {
		if($1 eq 'name') {
			$r = Conch::Model::DatacenterRackRole->from_name($2);
		} else {
			$c->status(404 => { error => "Not found" });
			return undef;
		}
	} else {
		$r = Conch::Model::DatacenterRackRole->from_id($c->param('id'));
	}

	if ($r) {
		$c->stash('rack_role' => $r);
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
	my $d = $c->validate_input('RackRoleCreate') or return;

	if(Conch::Model::DatacenterRackRole->from_name($d->{name})) {
		return $c->status(400 => { error => "name is already taken" });
	}

	my $r = Conch::Model::DatacenterRackRole->new($d->%*)->save();
	$c->status(303);
	$c->redirect_to($c->url_for("/rack_role/".$r->id));

}

=head2 get

Get a single rack role

=cut

sub get ($c) {
	$c->status(200, $c->stash('rack_role'));
}



=head2 get_all

Get all rack roles

=cut

sub get_all ($c) {
	$c->status(200, Conch::Model::DatacenterRackRole->all());
}


=head2 update

=cut


sub update ($c) {
	my $i = $c->validate_input('RackRoleUpdate') or return;

	if ($i->{name}) {
		if(Conch::Model::DatacenterRackRole->from_name($i->{name})) {
			return $c->status(400 => { error => "name is already taken" });
		}
	}
	$c->stash('rack_role')->update($i->%*)->save();
	$c->status(303 => "/rack_role/".$c->stash('rack_role')->id);
}


=head2 delete

Delete a rack role

=cut

sub delete ($c) {
	$c->stash('rack_role')->burn;
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

