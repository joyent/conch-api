package Conch::Controller::DeviceRoles;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;


=head2 get_all

Get all device roles

=cut

sub get_all ($c) {
	return $c->status(200, Conch::Model::DeviceRole->all());
}


=head2 get_one

Get a single device role

=cut

sub get_one ($c) {
	my $s = Conch::Model::DeviceRole->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;

	$c->status(200, $s);
}

=head2 create

Create a new device role

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $body = $c->req->json;
	if($body->{id}) {
		return $c->status(400 => { error => "'id' parameter not allowed'"});
	}

	return $c->status(400 => {
		error => "'hardware_product_id' parameter required"
	}) unless $body->{hardware_product_id};

	my $s = Conch::Model::DeviceRole->new(
		description         => $body->{description},
		hardware_product_id => $body->{hardware_product_id}
	)->save();
	$c->status(303 => "/device/role/".$s->id);
}


=head2 update

Update an existing device role. Does B<not> allow updating the service list

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $s = Conch::Model::DeviceRole->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;

	my $body = $c->req->json;

	if($body->{description}) {
		$s->update(description => $body->{description});
	}

	if($body->{hardware_product_id}) {
		$s->update(hardware_product_id => $body->{hardware_product_id});
	}

	$s->save;

	$c->status(303 => "/device/role/".$s->id);
}


=head2 delete

"Delete" a role by marking it as deactivated

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $s = Conch::Model::DeviceRole->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;

	$s->update(deactivated => Conch::Time->now)->save;
	return $c->status(204); 
}

=head2 add_service

Add a service to the role

=cut


sub add_service ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $s = Conch::Model::DeviceRole->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;

	my $body = $c->req->json;
	return $c->status(400 => { error => "'service' parameter required"})
		unless $body->{service};

	my $service = Conch::Model::DeviceService->from_id($body->{service});
	if ($service) {
		$s->add_service($body->{service});
		return $c->status(303 => "/device/role/".$s->id);
	} else {
		return $c->status(404 => {
			error => "Service does not exist"
		});
	}
}


=head2 remove_service

Remove a service from the role

=cut


sub remove_service ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $s = Conch::Model::DeviceRole->from_id($c->param('id'));
	return $c->status(404 => { error => "Not found" }) unless $s;
	return $c->status(404 => { error => "Not found" }) if $s->deactivated;
	
	my $body = $c->req->json;
	return $c->status(400 => { error => "'service' parameter required"})
		unless $body->{service};

	$s->remove_service($body->{service});
	$c->status(303 => "/device/role/".$s->id);
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

