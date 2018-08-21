package Conch::Controller::DeviceRoles;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;
with 'Conch::Role::MojoLog';


=head2 get_all

Get all device roles

=cut

sub get_all ($c) {
	my @roles = $c->db_device_roles->active->search(
		undef,
		{
			prefetch => 'device_role_services',
			order_by => 'device_role_services.device_role_service_id',
		}
	);

	$c->log->debug("Found ".scalar(@roles)." device roles");

	return $c->status(200, \@roles);
}

=head2 get_one

Get a single device role

=cut

sub get_one ($c) {

	my $device_role = $c->db_device_roles->active->find(
		$c->stash('device_role_id'),
		{
			prefetch => 'device_role_services',
			order_by => 'device_role_services.device_role_service_id',
		}
	);

	return $c->status(404 => { error => "Not found" }) unless $device_role;

	$c->log->debug("Found device role ".$device_role->id);

	$c->status(200, $device_role);
}

=head2 create

Create a new device role

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $body = $c->req->json;
	if($body->{id}) {
		$c->log->warn("Input failed validation"); # FIXME use the validator
		return $c->status(400 => { error => "'id' parameter not allowed'"});
	}

	unless($body->{hardware_product_id}) {
		$c->log->warn("Input failed validation"); # FIXME use the validator

		return $c->status(400 => {
			error => "'hardware_product_id' parameter required"
		});
	}

	my $device_role = $c->db_device_roles->create({
		description         => $body->{description},
		hardware_product_id => $body->{hardware_product_id},
	});

	$c->log->debug("Created device role ".$device_role->id);
	$c->status(303 => "/device/role/".$device_role->id);
}


=head2 update

Update an existing device role. Does B<not> allow updating the service list

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $device_role = $c->db_device_roles->active->find($c->stash('device_role_id'));

	return $c->status(404 => { error => "Not found" }) unless $device_role;
	$c->log->debug("Found device role ".$device_role->id);

	my $body = $c->req->json;

	$device_role->update({
		$body->{description} ? ( description => $body->{description} ) : (),
		$body->{hardware_product_id} ? ( hardware_product_id => $body->{hardware_product_id} ) : (),
		updated => \'NOW()',
	});

	$c->log->debug("Updated device role ".$device_role->id);

	$c->status(303 => "/device/role/".$device_role->id);
}


=head2 delete

"Delete" a role by marking it as deactivated

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $device_role = $c->db_device_roles->active->find($c->stash('device_role_id'));

	return $c->status(404 => { error => "Not found" }) unless $device_role;

	$c->log->debug("Found device role ".$device_role->id);

	$device_role->update({ deactivated => \'NOW()', updated => \'NOW()' });
	$c->log->debug("Deleted device role ".$device_role->id);
	return $c->status(204);
}

=head2 add_service

Add a service to the role

=cut


sub add_service ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $device_role = $c->db_device_roles->active->find($c->stash('device_role_id'));

	return $c->status(404 => { error => "Not found" }) unless $device_role;

	$c->log->debug("Found device role ".$device_role->id);

	my $body = $c->req->json;
	unless($body->{service}) {
		$c->log->warn("Input failed validation"); # FIXME use the validator
		return $c->status(400 => { error => "'service' parameter required"});
	}

	my $device_service = $c->db_device_services->find($body->{service});
	if ($device_service) {
		$c->log->debug("Found device service ".$device_service->id);

		$device_role->update_or_create_related('device_role_services',
			{ device_role_service_id => $body->{service} });

		$c->log->debug("Added device service ".$device_service->id." to device role ".$device_role->id);
		return $c->status(303 => "/device/role/".$device_role->id);
	} else {
		$c->log->debug("Failed to find device service ".$body->{service});
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

	my $device_role = $c->db_device_roles->active->find($c->stash('device_role_id'));

	return $c->status(404 => { error => "Not found" }) unless $device_role;
	return $c->status(404 => { error => "Not found" }) if $device_role->deactivated;

	my $body = $c->req->json;
	unless($body->{service}) {
		$c->log->warn("Input failed validation"); # FIXME use the validator
		return $c->status(400 => { error => "'service' parameter required"});
	}

	$device_role->delete_related('device_role_services',
		{ device_role_service_id => $body->{service} });

	$c->log->debug("Removed device service ".$body->{service}." from device role ".$device_role->id);
	$c->status(303 => "/device/role/".$device_role->id);
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
