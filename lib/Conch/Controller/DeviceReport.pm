package Conch::Controller::DeviceReport;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Mojo::JSON 'to_json';

=pod

=head1 NAME

Conch::Controller::DeviceReport

=head1 METHODS

=head2 process

Processes the device report, turning it into the various device_ tables as well
as running validations

Response uses the ValidationState json schema.

=cut

sub process ($c) {
	my $raw_report = $c->req->text;

	my $unserialized_report = $c->validate_input('DeviceReport');
	if (not $unserialized_report) {
		$c->log->debug('Device report input failed validation');

		if (not $c->db_devices->active->search({ id => $c->stash('device_id') })->exists) {
			$c->log->debug('Device id '.$c->stash('device_id').' does not exist; cannot store bad report');
			return;
		}

		# the "report" may not even be valid json, so we cannot store it in a jsonb field.
		my $device_report = $c->db_device_reports->create({
			device_id => $c->stash('device_id'),
			invalid_report => $raw_report,
		});
		$c->log->debug('Stored invalid device report for device id '.$c->stash('device_id'));
		return;
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

	if ($existing_device
		and $existing_device->latest_report_matches($raw_report)) {

		$existing_device->self_rs->latest_device_report->update({
			last_received => \'now()',
			received_count => \'received_count + 1',
		});

		if ($unserialized_report->{relay}) {
			$existing_device
				->search_related('device_relay_connections',
					{ relay_id => $unserialized_report->{relay}{serial} })
				->update_or_create({ last_seen => \'NOW()' });
		} else {
			$c->log->warn('received report without relay id (device_id '. $existing_device->id.')');
		}

		# this magically DTRT, without having to inject a ->as_subselect_rs,
		# because DBIx::Class::ResultSet::_chain_relationship understands how to wrap
		# joins using order by/limit into a subquery
		my $validation_state = $existing_device->self_rs->latest_device_report
			->related_resultset('validation_states')
			->order_by({ -desc => 'validation_states.created' })
			->rows(1)
			->single;

		if (not $validation_state) {
			# normally we should always find an associated validation_state record, because all
			# incoming device reports (that get stored) have validations run against them.
			$c->log->warn('Duplicate device report detected (device_report_id '
				. $validation_state->device_report_id
				. ' but could not find an associated validation_state record to return');

			# but we can try harder to find *something* to return, in most cases...
			$validation_state = $c->db_device_reports
				->matches_jsonb($raw_report)
				->related_resultset('validation_states')
				->order_by({ -desc => 'validation_states.created' })
				->rows(1)
				->single;

			return $c->status(400, { error => 'duplicate report; could not find relevant validation_state record to return from matching reports' }) if not $validation_state;
		}

		$c->log->debug('Duplicate device report detected (device_report_id '
			. $validation_state->device_report_id
			. '; returning previous validation_state (id ' . $validation_state->id .')');

		return $c->status(200, $validation_state);
	}

	# Update/create the device and create the device report
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
		deactivated         => undef,
	});

	$c->log->debug("Creating device report");
	my $device_report = $device->create_related('device_reports', {
		report    => $raw_report,
		# invalid, created, last_received, received_count all use defaults.
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

	my $validation_plan = $c->db_ro_validation_plans->active->search({ name => $validation_name })->single;

	return $c->status(500, { error => "failed to find validation plan" }) if not $validation_plan;

	$c->log->debug("Running validation plan ".$validation_plan->id);

	my $validation_state = Conch::ValidationSystem->new(
		schema => $c->schema,
		log => $c->log,
	)->run_validation_plan(
		validation_plan => $validation_plan,
		device => $c->db_ro_devices->find($device->id),
		device_report => $device_report,
	);
	$c->log->debug("Validations ran with result: ".$validation_state->status);

	# calculate the device health based on the validation results.
	# currently, since there is just one (hardcoded) plan per device, we can simply copy it
	# from the validation_state, but in the future we should query for the most recent
	# validation_state of each plan type and use the cumulative results to determine health.

	$device->update( { health => uc( $validation_state->status ), updated => \'NOW()' } );

	$c->status( 200, $validation_state );
}

=head2 _record_device_configuration

Uses a device report to populate configuration information about the given device

=cut

sub _record_device_configuration {
	my ( $c, $orig_device, $device, $dr ) = @_;

	my $log = $c->log;

	$c->schema->txn_do(
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
				$device->search_related('device_relay_connections',
						{ relay_id => $dr->{relay}{serial} })
					->update_or_create({ last_seen => \'NOW()' });
			}
			else {
				$c->log->warn('received report without relay id (device_id '. $device->id.')');
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

			my $device_specs = $device->related_resultset('device_spec')->update_or_create(
				{
					bios_firmware       => $dr->{bios_version},
					cpu_num             => $dr->{processor}->{count},
					cpu_type            => $dr->{processor}->{type},
					nics_num            => $nics_num,
					dimms_num           => $dr->{memory}->{count},
					ram_total           => $dr->{memory}->{total},
					# TODO: not setting hba_firmware
				}
			);

			$log->info("Created Device Spec for Device ".$device->id);

			if ($dr->{temp}) {
				$device->related_resultset('device_environment')->update_or_create({
					cpu0_temp    => $dr->{temp}->{cpu0},
					cpu1_temp    => $dr->{temp}->{cpu1},
					inlet_temp   => $dr->{temp}->{inlet},
					exhaust_temp => $dr->{temp}->{exhaust},
					# TODO: not setting psu0_voltage, psu1_voltage
					updated      => \'NOW()',
				});
				$c->log->info("Recorded environment for Device ".$device->id);
			}

			# Keep track of which disk serials have been previously recorded in the
			# DB but are no longer being reported due to a disk swap, etc.
			my @device_disk_serials = $device->related_resultset('device_disks')
				->active->get_column('serial_number')->all;
			my %inactive_serials;
			@inactive_serials{@device_disk_serials} = ();

			foreach my $disk ( keys %{ $dr->{disks} } ) {
				$log->debug("Device ".$device->id.": Recording disk: $disk");

				delete $inactive_serials{$disk};

				# if disk already exists on a different device, it will be relocated
				$c->db_device_disks->update_or_create(
					{
						device_id => $device->id,
						serial_number => $disk,
						$dr->{disks}{$disk}->%{qw(
							slot
							size
							vendor
							model
							firmware
							transport
							health
							drive_type
							temp
							enclosure
							hba
						)},
						deactivated   => undef,
						updated       => \'NOW()'
					},
				);
			}

			my @inactive_serials = keys %inactive_serials;

			# deactivate all disks that were previously recorded but are no longer
			# reported in the device report
			if (@inactive_serials) {
				$c->db_device_disks->search({ serial_number => { -in => \@inactive_serials } })->deactivate;
			}

			$dr->{disks}
				and $log->info("Recorded disk info for Device ".$device->id);

			my @device_nic_macs = map uc $device->device_nics->active->get_column('mac')->all;
			my %inactive_macs; @inactive_macs{@device_nic_macs} = ();

			foreach my $nic ( keys %{ $dr->{interfaces} } ) {

				my $mac = uc( $dr->{interfaces}->{$nic}->{mac} );

				$log->debug("Device ".$device->id.": Recording NIC: $mac");

				delete $inactive_macs{$mac};

				# if nic already exists on a different device, it will be relocated
				$c->db_device_nics->update_or_create(
					{
						device_id    => $device->id,
						mac          => $mac,
						iface_name   => $nic,
						iface_driver => '',
						iface_type   => $dr->{interfaces}->{$nic}->{product},
						iface_vendor => $dr->{interfaces}->{$nic}->{vendor},
						state        => $dr->{interfaces}->{$nic}->{state},
						ipaddr       => $dr->{interfaces}->{$nic}->{ipaddr},
						mtu          => $dr->{interfaces}->{$nic}->{mtu},
						updated      => \'NOW()',
						deactivated  => undef,
						# TODO: 'speed' is never set!
					},
				);

				my $nic_peers = $c->db_device_neighbors->update_or_create(
					{
						mac         => $mac,
						raw_text    => $dr->{interfaces}->{$nic}->{peer_text},
						peer_switch => $dr->{interfaces}->{$nic}->{peer_switch},
						peer_port   => $dr->{interfaces}->{$nic}->{peer_port},
						peer_mac    => $dr->{interfaces}->{$nic}->{peer_mac},
						updated     => \'NOW()'
						# TODO: not setting want_port, want_switch
					}
				);
			}

			my @inactive_macs = keys %inactive_macs;

			# deactivate all nics that were previously recorded but are no longer
			# reported in the device report
			if (@inactive_macs) {
				$c->db_device_nics->search({ mac => { -in => \@inactive_macs } })->deactivate;
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
