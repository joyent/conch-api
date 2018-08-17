=pod

=head1 NAME

Conch::Controller::DeviceReport

=head1 METHODS

=cut

package Conch::Controller::DeviceReport;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;
use Mojo::JSON;

with 'Conch::Role::MojoLog';

=head2 ct_import

This is a new way of bringing in device reports, featuring:

=over 2

=item content type based dispatch

=item Ability to specify report format version

=item Ability to dictate which validation plan is run

=back

User POSTs a device report with a content type like 

	Content-Type: application/vnd.joyent.conch.device.report+json;version=1;plan=Legacy Server;

Accepted parameters:

=over 2

=item version - the data format version. The only version known currently is 1

=item plan - the validation plan name to be executed against this report. For instance 'Conch v1 Legacy Plan: Server'

=back


=cut

use constant MEDIA_SUB_TYPE => "vnd.joyent.conch.device.report+json";

use Parse::MIME;
sub ct_import ($c) {
	my $raw_report = $c->req->body;

	my $device = $c->db_devices->find({
		id => $c->stash('current_device')->id
	}); #DBIC4lyfe

	# We should never ever hit this condition since 'under' already found the device
	# using the Model libraries. But just in case...
	if(not $device) {
		return $c->render(status => 500, json => { error => "An error occurred fetching the device from DBIC" });
	}


	my ($media_type, $media_subtype, $params) = Parse::MIME::parse_mime_type(
		$c->req->headers->content_type
	);

	$c->log->debug("Content type: ".$c->req->headers->content_type);

	if($media_subtype eq MEDIA_SUB_TYPE) {
		my %args = $params->%*;

		if($args{version} != 1) {
			return $c->render(status => 415, json => { error => "Unsupported version" });
		}

		my $unserialized_report = $c->validate_input('DeviceReport');
		if(not $unserialized_report) {
			return; # JSON validator will throw the proper error response
		}

		my $vp = Conch::Model::ValidationPlan->lookup_by_name($args{plan});
		if(not $vp) {
			return $c->render(status => 415, json => { error => "Unknown plan" });
		}

		$vp->log($c->log);
		$c->log->debug("Running validation plan ".$vp->id);

		my $state = $vp->run_with_state(
			$device->id,
			$unserialized_report,
		);

		$c->log->debug("Validations ran with result: ".$state->status);
		$device->update( { health => uc( $state->status ) } );

		if($state->status eq $state->STATUS_ERROR) {
			$c->log->error("Parsing the report generated an error. Refusing to load into database.");
			$c->log->debug($raw_report);
			return $c->render(
				status => 422,
				json => {
					error => "Validation plan threw an unrecoverable error"
				}
			);
		}

		if($args{version} == 1) {
			$c->log->debug("Recording device report, version ".$args{version});
			$c->_record_device_report(
				$unserialized_report,
				$raw_report
			);
		}

		$c->render(status => 204, json => {});
	} else {
		return $c->render(
			status => 415,
			json => {
				error => "Unsupported media sub type ".$media_subtype
			}
		);
	}

	# FIXME return a 201 with a Location header pointing to the validation state/results data
	return;
}

=head2 process

Processes the device report using the Legacy report code base

=cut

sub process ($c) {
	my $device_report = $c->validate_input('DeviceReport');
	return if not $device_report;
	my $raw_report = $c->req->body;

	my $maybe_hw;

	if ( $device_report->{device_type}
		&& $device_report->{device_type} eq "switch" )
	{
		$maybe_hw = Conch::Model::HardwareProduct->lookup_by_name(
			$device_report->{product_name}
		);
		return $c->status(409, {
			error => "Hardware product name '".$device_report->{product_name}."' does not exist"
		}) unless ($maybe_hw);

	} else {
		$maybe_hw = Conch::Model::HardwareProduct->lookup_by_sku(
			$device_report->{sku}
		);

		return $c->status(409, {
			error => "Hardware product SKU '".$device_report->{sku}."' does not exist"
		}) unless ($maybe_hw);

	}

	# Use the old device report recording and device validation code for now.
	# This will be removed when OPS-RFD 22 is implemented
	$c->log->debug("Recording device report");
	my ( $device, $report_id ) = $c->_record_device_report(
		$device_report,
		$raw_report
	);


	my $validation_name;
	if ( $device_report->{device_type}
		&& $device_report->{device_type} eq "switch" )
	{
		$validation_name = 'Conch v1 Legacy Plan: Switch';
	} else {
		$validation_name = 'Conch v1 Legacy Plan: Server';
	}

	$c->log->debug("Attempting to validation with plan '$validation_name'");

	my $validation_plan = Conch::Model::ValidationPlan->lookup_by_name($validation_name);

	# [2018-07-16 sungo] - As we grow this logic to be smarter and more
	# interesting, it will probably be ok to not find a validation plan. For
	# now, everything needs to validate using one of the legacy plans. It's a
	# super big problem if they don't exist so we explode.
	unless($validation_plan) {
		Mojo::Exception->throw(__PACKAGE__.": Could not find a validation plan");
	}

	$c->log->debug("Running validation plan ".$validation_plan->id);
	$validation_plan->log($c->log);
	my $validation_state = $validation_plan->run_with_state(
		$device->id,
		$device_report
	);
	$c->log->debug("Validations ran with result: ".$validation_state->status);

	# this uses the DBIC object from _record_device_report to do the update
	$device->update( { health => uc( $validation_state->status ) } );

	$c->status( 200, $validation_state );
}

=head2 _record_device_report

Record device report and device details from the report

=cut

sub _record_device_report {
	my ( $c, $dr, $raw_report ) = @_;

	my $schema = $c->schema;
	my $log = $c->log;

	my $hw;

	if ($dr->{device_type} && $dr->{device_type} eq "switch")
	{
		$hw = $schema->resultset('HardwareProduct')->find(
		{
			name => $dr->{product_name}
		}
		);
		$hw or die $log->critical("Product $dr->{product_name} not found");
	} else {
		$hw = $schema->resultset('HardwareProduct')->find(
		{
			sku => $dr->{sku}
		}
		);
		$hw or die $log->critical("Product $dr->{sku} not found");
	}

	my $hw_profile = $hw->hardware_product_profile;
	$hw_profile
		or die $log->criticalf(
		"Hardware product '%s' exists but does not have a hardware profile",
		$hw->name );

	$log->info("Ready to record report for Device $dr->{serial_number}");

	my $device;
	my $device_report;

	$schema->txn_do(
		sub {

			my $prev_device =
				$schema->resultset('Device')->find( { id => $dr->{serial_number} } );

			my $prev_uptime = $prev_device && $prev_device->uptime_since;

			$device = $schema->resultset('Device')->update_or_create(
				{
					id               => $dr->{serial_number},
					system_uuid      => $dr->{system_uuid},
					hardware_product_id => $hw->id,
					state            => $dr->{state},
					health           => "UNKNOWN",
					last_seen        => \'NOW()',
					uptime_since     => $dr->{uptime_since} || $prev_uptime
				}
			);
			my $device_id = $device->id;
			$log->info("Created Device $device_id");

			# Add a reboot count if there's not a previous uptime but one in this
			# report (i.e. first uptime reported), or if the previous uptime date is
			# less than the the current one (i.e. there has been a reboot)
			_add_reboot_count($device)
				if ( !$prev_uptime && $device->{uptime_since} )
				|| $device->{uptime_since} && $prev_uptime < $device->{uptime_since};

			_device_relay_connect( $schema, $device_id, $dr->{relay}{serial} )
				if $dr->{relay};

			$device_report = $schema->resultset('DeviceReport')->create(
				{
					device_id => $device_id,
					report    => $raw_report,
				}
			);

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
					device_id     => $device_id,
					product_id    => $hw_profile->id,
					bios_firmware => $dr->{bios_version},
					cpu_num       => $dr->{processor}->{count},
					cpu_type      => $dr->{processor}->{type},
					nics_num      => $nics_num,
					dimms_num     => $dr->{memory}->{count},
					ram_total     => $dr->{memory}->{total},
				}
			);

			$log->info("Created Device Spec for Device $device_id");

			$schema->resultset('DeviceEnvironment')->update_or_create(
				{
					device_id    => $device->id,
					cpu0_temp    => $dr->{temp}->{cpu0},
					cpu1_temp    => $dr->{temp}->{cpu1},
					inlet_temp   => $dr->{temp}->{inlet},
					exhaust_temp => $dr->{temp}->{exhaust},
				}
			) if $dr->{temp};

			$dr->{temp}
				and $log->info("Recorded environment for Device $device_id");

			my @device_disks = $schema->resultset('DeviceDisk')->search(
				{
					device_id   => $device_id,
					deactivated => { '=', undef }
				}
			)->all;

			# Keep track of which disk serials have been previously recorded in the
			# DB but are no longer being reported due to a disk swap, etc.
			my %inactive_serials = map { $_->serial_number => 1 } @device_disks;

			foreach my $disk ( keys %{ $dr->{disks} } ) {
				$log->debug("Device $device_id: Recording disk: $disk");

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
				and $log->info("Recorded disk info for Device $device_id");

			my @device_nics = $schema->resultset('DeviceNic')->search(
				{
					device_id   => $device_id,
					deactivated => { '=', undef }
				}
			)->all;

			my %inactive_macs = map { uc( $_->mac ) => 1 } @device_nics;

			foreach my $nic ( keys %{ $dr->{interfaces} } ) {

				my $mac = uc( $dr->{interfaces}->{$nic}->{mac} );

				$log->debug("Device $device_id: Recording NIC: $mac");

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
						updated      => \'NOW()',
						deactivated  => undef
					}
				);

				my $nic_state = $schema->resultset('DeviceNicState')->update_or_create(
					{
						mac     => $mac,
						state   => $dr->{interfaces}->{$nic}->{state},
						ipaddr  => $dr->{interfaces}->{$nic}->{ipaddr},
						mtu     => $dr->{interfaces}->{$nic}->{mtu},
						updated => \'NOW()'
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
	return ( $device, $device_report->id );
}

sub _add_reboot_count {
	my $device = shift;

	my $reboot_count =
		$device->device_settings->find_or_new( { name => 'reboot_count' } );
	$reboot_count->updated( \'NOW()' );

	if ( $reboot_count->in_storage ) {
		$reboot_count->value( 1 + $reboot_count->value );
		$reboot_count->update;
	}
	else {
		$reboot_count->value(0);
		$reboot_count->insert;
	}
}

sub _device_relay_connect {
	my ( $schema, $device_id, $relay_id ) = @_;

	# 'first_seen' column will only be written on create. It should remain
	# untouched on updates
	$schema->resultset('DeviceRelayConnection')->update_or_create(
		{
			device_id => $device_id,
			relay_id  => $relay_id,
			last_seen => \'NOW()'
		}
	);
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
