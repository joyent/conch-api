package Conch::Controller::DeviceServices;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;


=head2 under

Handles looking up the object by id or name depending on the url pattern

=cut

sub under ($c) {
	my $s;

	if($c->param('id') =~ /^(.+?)\=(.+)$/) {
		if($1 eq 'name') {
			$s = Conch::Model::DeviceService->from_name($2);
		}
	} else {
		$s = Conch::Model::DeviceService->from_id($c->param('id'));
	}

	if ($s) {
		if($s->deactivated) {
			$c->status(404 => { error => "Not found" });
			return undef;
		}
		$c->stash('deviceservice' => $s);
		return 1;
	} else {
		$c->status(404 => { error => "Not found" });
		return undef;
	}

}


=head2 get_all

Get all device services

=cut

sub get_all ($c) {
	return $c->status(200, Conch::Model::DeviceService->all());
}


=head2 get_one

Get a single device service

=cut

sub get_one ($c) {
	$c->status(200, $c->stash('deviceservice'));
}

=head2 create

Create a new device service

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $body = $c->req->json;
	if($body->{id}) {
		return $c->status(400 => { error => "'id' parameter not allowed'"});
	}
	return $c->status(400 => { error => "'name' parameter required"})
		unless $body->{name};

	if(Conch::Model::DeviceService->from_name($body->{name})) {
		return $c->status(400 => {
			error => "The name ".$body->{name}."is taken"
		});
	}

	my $s = Conch::Model::DeviceService->new(name => $body->{name})->save();
	$c->status(303 => "/device/service/".$s->id);
}


=head2 update

Update an existing device service

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $s = $c->stash('deviceservice');

	my $body = $c->req->json;

	if($body->{name} and ($body->{name} ne $s->name)) {
		if(Conch::Model::DeviceService->from_name($body->{name})) {
			return $c->status(400 => {
				error => "A service named '".$body->{name}." already exists"
			});
		}
	}

	$s->update(name => $body->{name})->save;
	$c->status(303 => "/device/service/".$s->id);
}


=head2 delete

"Delete" a service by marking it as deactivated

=cut

sub delete ($c) {
	$c->stash('deviceservice')->burn;
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
