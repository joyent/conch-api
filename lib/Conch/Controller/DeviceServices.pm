package Conch::Controller::DeviceServices;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

with 'Conch::Role::MojoLog';

=head2 find_device_service

Handles looking up the object by id or name depending on the url pattern

=cut

sub find_device_service ($c) {
	my $device_service;

	if($c->stash('device_service_id') =~ /^(.+?)\=(.+)$/) {
		my ($k, $v) = ($1, $2);
		if($k eq 'name') {
			$c->log->debug("Looking up device service by name $v");
			$device_service = $c->db_device_services->find({ name => $v });
		} else {
			$c->log->warn("Unknown identifier '$k'");
			$c->status(404 => { error => "Not found" });
			return undef;
		}
	} else {
		$c->log->debug("Looking up device service by id ".$c->stash('device_service_id'));
		$device_service = $c->db_device_services->find($c->stash('device_service_id'));
	}

	if ($device_service) {
		$c->log->debug("Found device service ".$device_service->id);

		# TODO. device_service.deactivated does not exist.
		# if($device_service->deactivated) {
		# 	$c->log->debug("Device service ".$device_service->id." is deactivated");
		# 	$c->status(404 => { error => "Not found" });
		# 	return undef;
		# }

		$c->stash('device_service' => $device_service);
		return 1;
	} else {
		$c->log->debug("Failed to find device service");
		$c->status(404 => { error => "Not found" });
		return undef;
	}

}


=head2 get_all

Get all device services

=cut

sub get_all ($c) {
	my @device_services = $c->db_device_services->all;
	$c->log->debug("Found ".scalar(@device_services)." device services");
	return $c->status(200 => \@device_services);
}


=head2 get_one

Get a single device service

=cut

sub get_one ($c) {
	$c->status(200, $c->stash('device_service'));
}

=head2 create

Create a new device service

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $body = $c->req->json;
	if($body->{id}) {
		$c->log->warn("Input failed validation"); #FIXME use the validator
		return $c->status(400 => { error => "'id' parameter not allowed'"});
	}

	unless($body->{name}) {
		$c->log->warn("Input failed validation"); #FIXME use the validator
		return $c->status(400 => { error => "'name' parameter required"});
	}

	if ($c->db_device_services->find({ name => $body->{name} })) {
		$c->log->debug("Name conflict on ".$body->{name});
		return $c->status(400 => {
			error => "The name ".$body->{name}."is taken"
		});
	}

	my $device_service = $c->db_device_services->create({ name => $body->{name} });
	$c->log->debug("Created device service ".$device_service->id);
	$c->status(303 => "/device/service/".$device_service->id);
}


=head2 update

Update an existing device service

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $device_service = $c->stash('device_service');

	my $body = $c->req->json;

	if($body->{name} and ($body->{name} ne $device_service->name)) {
		if ($c->db_device_services->find({ name => $body->{name} })) {
			$c->log->debug("Name conflict on ".$body->{name});
			return $c->status(400 => {
				error => "A service named '".$body->{name}." already exists"
			});
		}
	}

	$device_service->update({ name => $body->{name}, updated => \'NOW()' });
	$c->log->debug("Updated device service ".$device_service->id);
	$c->status(303 => "/device/service/".$device_service->id);
}


=head2 delete

Delete a service

=cut

sub delete ($c) {
	# TODO: set 'deactivated' instead of removing entirely?
	$c->stash('device_service')->delete;
	$c->log->debug("Deleted device service ".$c->stash('device_service')->id);
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
