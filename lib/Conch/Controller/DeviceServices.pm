package Conch::Controller::DeviceServices;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;
with 'Conch::Role::MojoLog';

=head2 find_device_service

Handles looking up the object by id or name depending on the url pattern

=cut

sub find_device_service ($c) {
	my $s;

	if($c->stash('device_service_id') =~ /^(.+?)\=(.+)$/) {
		my ($k, $v) = ($1, $2);
		if($k eq 'name') {
			$c->log->debug("Looking up device service by name $v");
			$s = Conch::Model::DeviceService->from_name($v);
		} else {
			$c->log->warn("Unknown identifier '$k'");
			$c->status(404 => { error => "Not found" });
			return undef;
		}
	} else {
		$c->log->debug("Looking up device service by id ".$c->stash('device_service_id'));
		$s = Conch::Model::DeviceService->from_id($c->stash('device_service_id'));
	}

	if ($s) {
		$c->log->debug("Found device service ".$s->id);
		if($s->deactivated) {
			$c->log->debug("Device service ".$s->id." is deactivated");
			$c->status(404 => { error => "Not found" });
			return undef;
		}

		$c->stash('device_service' => $s);
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
	my $s = Conch::Model::DeviceService->all();
	$c->log->debug("Found ".scalar($s->@*)." device services");
	return $c->status(200 => $s);
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

	if(Conch::Model::DeviceService->from_name($body->{name})) {
		$c->log->debug("Name conflict on ".$body->{name});
		return $c->status(400 => {
			error => "The name ".$body->{name}."is taken"
		});
	}

	my $s = Conch::Model::DeviceService->new(name => $body->{name})->save();
	$c->log->debug("Created device service ".$s->id);
	$c->status(303 => "/device/service/".$s->id);
}


=head2 update

Update an existing device service

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $s = $c->stash('device_service');

	my $body = $c->req->json;

	if($body->{name} and ($body->{name} ne $s->name)) {
		if(Conch::Model::DeviceService->from_name($body->{name})) {
			$c->log->debug("Name conflict on ".$body->{name});
			return $c->status(400 => {
				error => "A service named '".$body->{name}." already exists"
			});
		}
	}

	$s->update(name => $body->{name})->save;
	$c->log->debug("Updated device service ".$s->id);
	$c->status(303 => "/device/service/".$s->id);
}


=head2 delete

"Delete" a service by marking it as deactivated

=cut

sub delete ($c) {
	$c->stash('device_service')->burn;
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
