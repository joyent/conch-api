package Conch::Controller::DeviceServices;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;


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
	my $s = Conch::Model::DeviceService->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;

	$c->status(200, $s);
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

	my $s = Conch::Model::DeviceService->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;

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
	my $s = Conch::Model::DeviceService->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;

	$s->burn;
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

