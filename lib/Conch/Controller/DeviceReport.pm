=pod

=head1 NAME

Conch::Controller::DeviceReport

=head1 METHODS

=cut

package Conch::Controller::DeviceReport;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;

with 'Conch::Role::MojoLog';

=head2 process

Processes the device report, turning it into the various device_ tables as well
as running validations

Response uses the ValidationState json schema.

=cut

sub process ($c) {
	my $raw_report = $c->req->body;

	my $unserialized_report = $c->validate_input('DeviceReport');
	if(not $unserialized_report) {
		$c->log->debug('Device report input failed validation');
		return $c->status(400);
	}

	# Make sure the API and device report agree on who we're talking about
	if ($c->stash('device_id') ne $unserialized_report->{serial_number}) {
		return $c->render(status => 422, json => {
			error => "Serial number provided to the API does not match the report data."
		});
	}

	my $hw;
	# Make sure that the remote side is telling us about a hardware product we understand
	if ($unserialized_report->{device_type} && $unserialized_report->{device_type} eq "switch") {
		$hw = $c->db_hardware_products->active->search(
			{ name => $unserialized_report->{product_name} },
			{ prefetch => 'hardware_product_profile' },
		)->single;
	} else {
		$hw = $c->db_hardware_products->active->search(
			{ sku => $unserialized_report->{sku} },
			{ prefetch => 'hardware_product_profile' },
		)->single;

		if(not $hw) {
			# this will warn if more than one matching row is found
			$hw = $c->db_hardware_products->active->search(
				{ legacy_product_name => $unserialized_report->{product_name}, },
				{ prefetch => 'hardware_product_profile' },
			)->single;
		}
	}

	if(not $hw) {
		return $c->render(status => 409, json => {
			error => "Could not locate hardware product"
		});
	}

	if(not $hw->hardware_product_profile) {
		return $c->render(status => 409, json => {
			error => "Hardware product does not contain a profile"
		});
	}

	my $existing_device = $c->db_devices->active->find($c->stash('device_id'));

	# Update/create the device and create the device report
	# FIXME [2018-08-23 sungo] we need device report dedup here
	$c->log->debug("Updating or creating device ".$c->stash('device_id'));
	
	my $uptime = $unserialized_report->{uptime_since} ? $unserialized_report->{uptime_since} : 
		$existing_device ? $existing_device->uptime_since : undef;

	my $device = $c->db_devices->update_or_create({
		id                  => $c->stash('device_id'),
		system_uuid         => $unserialized_report->{system_uuid},
		hardware_product_id => $hw->id,
		state               => $unserialized_report->{state},
		health              => "UNKNOWN",
		last_seen           => \'NOW()',
		uptime_since        => $uptime,
		hostname            => $unserialized_report->{os}{hostname},
		updated             => \'NOW()',
	});

	$c->log->debug("Creating device report");
	my $device_report = $device->create_related('device_reports', {
		report    => $raw_report,
	});
	$c->log->info("Created device report ".$device_report->id);


	$c->log->debug("Recording device configuration");
	$c->_record_device_configuration(
		$existing_device,
		$device,
		$unserialized_report,
	);


	# Time for validations http://www.space.ca/wp-content/uploads/2017/05/giphy-1.gif
	my $validation_name = 'Conch v1 Legacy Plan: Server';

	if ( $unserialized_report->{device_type}
		&& $unserialized_report->{device_type} eq "switch" )
	{
		$validation_name = 'Conch v1 Legacy Plan: Switch';
	}

	$c->log->debug("Attempting to validate with plan '$validation_name'");

	my $validation_plan = Conch::Model::ValidationPlan->lookup_by_name($validation_name);
	return $c->status(500, { error => "failed to find validation plan" }) if not $validation_plan;
	$validation_plan->log($c->log);

	# [2018-07-16 sungo] - As we grow this logic to be smarter and more
	# interesting, it will probably be ok to not find a validation plan. For
	# now, everything needs to validate using one of the legacy plans. It's a
	# super big problem if they don't exist so we explode.
	unless($validation_plan) {
		Mojo::Exception->throw(__PACKAGE__.": Could not find a validation plan");
	}

	$c->log->debug("Running validation plan ".$validation_plan->id);
	my $validation_state = $validation_plan->run_with_state(
		$device->id,
		$unserialized_report, # FIXME this needs to be a DBIC object so we can tie the validation results to a the report ID
	);
	$c->log->debug("Validations ran with result: ".$validation_state->status);

	# this uses the DBIC object from _record_device_report to do the update
	$device->update( { health => uc( $validation_state->status ), updated => \'NOW()' } );

	$c->status( 200, $validation_state );
}

=head2 _record_device_configuration

Uses a device report to populate configuration information about the given device

=cut

sub _record_device_configuration {
	my ( $c, $orig_device, $device, $dr ) = @_;

	my $schema = $c->schema;
	my $log = $c->log;

	$schema->txn_do(
		sub {
			# Add a reboot count if there's not a previous uptime but one in this
			# report (i.e. first uptime reported), or if the previous uptime date is
			# less than the the current one (i.e. there has been a reboot)
			my $prev_uptime;
			if($orig_device) {
				$prev_uptime = $orig_device->uptime_since;
			}
			_add_reboot_count($device)
				if ( !$prev_uptime && $device->uptime_since )
				|| $device->uptime_since && $prev_uptime < $device->uptime_since;

			if($dr->{relay}) {
				# 'first_seen' column will only be written on create. It should remain
				# untouched on updates
				$schema->resultset('DeviceRelayConnection')->update_or_create(
					{
						device_id => $device->id,
						relay_id  => $dr->{relay}{serial},
						last_seen => \'NOW()',
					}
				);
			}

			my $nics_num = 0;
			# switches use the 'media' attribute, and servers use 'interfaces'
			if ( $dr->{media} ) {
				for my $port ( keys %{ $dr->{media} } ) {
					for my $nic ( keys %{ $dr->{media}->{$port} } ) {
						$nics_num++;
					}
				}
			} else {
				$nics_num = scalar( keys %{ $dr->{interfaces} } );
			}

			my $device_specs = $schema->resultset('DeviceSpec')->update_or_create(
				{
					device_id           => $device->id,
					hardware_product_id => $device->hardware_product->hardware_product_profile->id,
					bios_firmware       => $dr->{bios_version},
					cpu_num             => $dr->{processor}->{count},
					cpu_type            => $dr->{processor}->{type},
					nics_num            => $nics_num,
					dimms_num           => $dr->{memory}->{count},
					ram_total           => $dr->{memory}->{total},
				}
			);

			$log->info("Created Device Spec for Device ".$device->id);

			$schema->resultset('DeviceEnvironment')->update_or_create(
				{
					device_id    => $device->id,
					cpu0_temp    => $dr->{temp}->{cpu0},
					cpu1_temp    => $dr->{temp}->{cpu1},
					inlet_temp   => $dr->{temp}->{inlet},
					exhaust_temp => $dr->{temp}->{exhaust},
					updated      => \'NOW()',
				}
			) if $dr->{temp};

			$dr->{temp}
				and $log->info("Recorded environment for Device ".$device->id);

			my @device_disks = $schema->resultset('DeviceDisk')->search(
				{
					device_id   => $device->id,
					deactivated => { '=', undef }
				}
			)->all;

			# Keep track of which disk serials have been previously recorded in the
			# DB but are no longer being reported due to a disk swap, etc.
			my %inactive_serials = map { $_->serial_number => 1 } @device_disks;

			foreach my $disk ( keys %{ $dr->{disks} } ) {
				$log->debug("Device ".$device->id.": Recording disk: $disk");

				if ( $inactive_serials{$disk} ) {
					$inactive_serials{$disk} = 0;
				}

				my $disk_rs = $schema->resultset('DeviceDisk')->update_or_create(
					{
						device_id     => $device->id,
						serial_number => $disk,
						slot          => $dr->{disks}->{$disk}->{slot},
						hba           => $dr->{disks}->{$disk}->{hba},
						enclosure     => $dr->{disks}->{$disk}->{enclosure},
						vendor        => $dr->{disks}->{$disk}->{vendor},
						health        => $dr->{disks}->{$disk}->{health},
						size          => $dr->{disks}->{$disk}->{size},
						model         => $dr->{disks}->{$disk}->{model},
						temp          => $dr->{disks}->{$disk}->{temp},
						drive_type    => $dr->{disks}->{$disk}->{drive_type},
						transport     => $dr->{disks}->{$disk}->{transport},
						firmware      => $dr->{disks}->{$disk}->{firmware},
						deactivated   => undef,
						updated       => \'NOW()'
					}
				);
			}

			my @inactive_serials =
				grep { $inactive_serials{$_} } keys %inactive_serials;

			# Deactivate all disks that were previously recorded but are no longer
			# reported in the device report
			if ( scalar @inactive_serials ) {
				$schema->resultset('DeviceDisk')
					->search_rs( { serial_number => { -in => \@inactive_serials } } )
					->update( { deactivated => \'NOW()', updated => \'NOW()' } );
			}

			$dr->{disks}
				and $log->info("Recorded disk info for Device ".$device->id);

			# TODO: $device->device_nics->active->get_column('mac')
			my @device_nics = $schema->resultset('DeviceNic')->search(
				{
					device_id   => $device->id,
					deactivated => { '=', undef }
				}
			)->all;

			my %inactive_macs = map { uc( $_->mac ) => 1 } @device_nics;

			foreach my $nic ( keys %{ $dr->{interfaces} } ) {

				my $mac = uc( $dr->{interfaces}->{$nic}->{mac} );

				$log->debug("Device ".$device->id.": Recording NIC: $mac");

				if ( $inactive_macs{$mac} ) {
					$inactive_macs{$mac} = 0;
				}

				my $nic_rs = $schema->resultset('DeviceNic')->update_or_create(
					{
						mac          => $mac,
						device_id    => $device->id,
						iface_name   => $nic,
						iface_type   => $dr->{interfaces}->{$nic}->{product},
						iface_vendor => $dr->{interfaces}->{$nic}->{vendor},
						iface_driver => '',
						state   => $dr->{interfaces}->{$nic}->{state},
						ipaddr  => $dr->{interfaces}->{$nic}->{ipaddr},
						mtu     => $dr->{interfaces}->{$nic}->{mtu},
						updated      => \'NOW()',
						deactivated  => undef
						# TODO: 'speed' is never set!
					}
				);

				my $nic_peers = $schema->resultset('DeviceNeighbor')->update_or_create(
					{
						mac         => $mac,
						raw_text    => $dr->{interfaces}->{$nic}->{peer_text},
						peer_switch => $dr->{interfaces}->{$nic}->{peer_switch},
						peer_port   => $dr->{interfaces}->{$nic}->{peer_port},
						peer_mac    => $dr->{interfaces}->{$nic}->{peer_mac},
						updated     => \'NOW()'
					}
				);
			}

			my @inactive_macs =
				grep { $inactive_macs{$_} } keys %inactive_macs;

			# Deactivate all nics that were previously recorded but are no longer
			# reported in the device report
			if ( scalar @inactive_macs ) {
				$schema->resultset('DeviceNic')
					->search_rs( { mac => { -in => \@inactive_macs } } )
					->update( { deactivated => \'NOW()', updated => \'NOW()' } );
			}

		}
	);
}

sub _add_reboot_count {
	my $device = shift;

	my $reboot_count = $device->find_or_new_related('device_settings', {
		deactivated => undef,
		name => 'reboot_count'
	});

	if ( $reboot_count->in_storage ) {
		$reboot_count->update({
			value => 1 + $reboot_count->value,
			updated => \'NOW()',
		});
	}
	else {
		$reboot_count->value(0);
		$reboot_count->insert;
	}
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
