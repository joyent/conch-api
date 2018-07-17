=pod

=head1 NAME

Conch::Legacy::Control::Problem - B<LEGACY MODULE>

=head1 METHODS

=cut
package Conch::Legacy::Control::Problem;

use strict;
use warnings;
use Mojo::JSON 'decode_json';

use Data::Printer;

use Exporter 'import';
our @EXPORT_OK = qw( get_problems );

=head2 get_problems

Build a collection of failing devices in a workspace

=cut
# The report / validation format is not normalized yet, so this is going to be
# a giant mess. Sorry. -- bdha
sub get_problems {
	my ( $schema, $user_id, $workspace_id ) = @_;

	my $criteria = _get_validation_criteria($schema);

	my @failing_user_devices;
	my @unreported_user_devices;
	my @unlocated_user_devices;
	foreach my $d ( _workspace_devices( $schema, $workspace_id ) ) {
		if ( $d->health eq 'FAIL' ) {
			push @failing_user_devices, $d;
		}
		if ( $d->health eq 'UNKNOWN' ) {
			push @unreported_user_devices, $d;
		}
	}

	foreach my $d ( _unlocated_devices( $schema, $user_id ) ) {
		push @unlocated_user_devices, $d;
	}

	my $failing_problems = {};
	foreach my $device (@failing_user_devices) {
		my $device_id = $device->id;

		$failing_problems->{$device_id}{health} = $device->health;
		$failing_problems->{$device_id}{location} =
			_device_rack_location( $schema, $device_id );

		my $report = _latest_device_report( $schema, $device_id );
		$failing_problems->{$device_id}{report_id} = $report->id;
		my @failures = _validation_failures( $schema, $criteria, $report->id );
		$failing_problems->{$device_id}{problems} = \@failures;
	}

	my $unreported_problems = {};
	foreach my $device (@unreported_user_devices) {
		my $device_id = $device->id;

		$unreported_problems->{$device_id}{health} = $device->health;
		$unreported_problems->{$device_id}{location} =
			_device_rack_location( $schema, $device_id );
	}

	my $unlocated_problems = {};
	foreach my $device (@unlocated_user_devices) {
		my $device_id = $device->id;

		$unlocated_problems->{$device_id}{health} = $device->health;
		my $report = _latest_device_report( $schema, $device_id );
		$unlocated_problems->{$device_id}{report_id} = $report->id;
		my @failures = _validation_failures( $schema, $criteria, $report->id );
		$unlocated_problems->{$device_id}{problems} = \@failures;
	}

	return {
		failing    => $failing_problems,
		unreported => $unreported_problems,
		unlocated  => $unlocated_problems
	};
}

sub _validation_failures {
	my ( $schema, $criteria, $report_id ) = @_;
	my @failures;

	my @validation_report = _device_validation_report( $schema, $report_id );
	foreach my $v (@validation_report) {
		my $fail = {};
		if ( $v->{status} eq 0 ) {
			$fail->{criteria}{id} = $v->{criteria_id} || undef;
			$fail->{criteria}{component} =
				$criteria->{ $v->{criteria_id} }{component} || undef;
			$fail->{criteria}{condition} =
				$criteria->{ $v->{criteria_id} }{condition} || undef;
			$fail->{criteria}{min}  = $criteria->{ $v->{criteria_id} }{min}  || undef;
			$fail->{criteria}{warn} = $criteria->{ $v->{criteria_id} }{warn} || undef;
			$fail->{criteria}{crit} = $criteria->{ $v->{criteria_id} }{crit} || undef;

			$fail->{component_id}   = $v->{component_id}   || undef;
			$fail->{component_name} = $v->{component_name} || undef;
			$fail->{component_type} = $v->{component_type} || undef;
			$fail->{log}            = $v->{log}            || undef;
			$fail->{metric}         = $v->{metric}         || undef;

			push @failures, $fail;
		}
	}

	return @failures;
}

sub _get_validation_criteria {
	my ($schema) = @_;

	my $criteria = {};

	my @rs = $schema->resultset('DeviceValidateCriteria')->search( {} )->all;
	foreach my $c (@rs) {
		$criteria->{ $c->id }{product_id} = $c->product_id || undef;
		$criteria->{ $c->id }{component}  = $c->component  || undef;
		$criteria->{ $c->id }{condition}  = $c->condition  || undef;
		$criteria->{ $c->id }{vendor}     = $c->vendor     || undef;
		$criteria->{ $c->id }{model}      = $c->model      || undef;
		$criteria->{ $c->id }{string}     = $c->string     || undef;
		$criteria->{ $c->id }{min}        = $c->min        || undef;
		$criteria->{ $c->id }{warn}       = $c->warn       || undef;
		$criteria->{ $c->id }{crit}       = $c->crit       || undef;
	}

	return $criteria;
}

sub _workspace_devices {
	my ( $schema, $workspace_id ) = @_;
	return $schema->resultset('WorkspaceDevices')
		->search( {}, { bind => [$workspace_id] } )->all;
}

sub _unlocated_devices {
	my ( $schema, $user_id ) = @_;
	return $schema->resultset('UnlocatedUserRelayDevices')
		->search( {}, { bind => [$user_id] } )->all;
}

# Gives a hash of Rack and Datacenter location details
sub _device_rack_location {
	my ( $schema, $device_id ) = @_;

	my $location;
	my $device_location = _device_location( $schema, $device_id );
	if ($device_location) {
		my $rack_info = _get_rack( $schema, $device_location->rack_id );
		my $datacenter =
			_get_datacenter_room( $schema, $rack_info->datacenter_room_id );
		my $target_hardware =
			_get_target_hardware_product( $schema, $rack_info->id,
			$device_location->rack_unit );

		$location->{rack}{id}   = $device_location->rack_id;
		$location->{rack}{unit} = $device_location->rack_unit;
		$location->{rack}{name} = $rack_info->name;
		$location->{rack}{role} = $rack_info->role->name;

		$location->{target_hardware_product}{id}    = $target_hardware->id;
		$location->{target_hardware_product}{name}  = $target_hardware->name;
		$location->{target_hardware_product}{alias} = $target_hardware->alias;
		$location->{target_hardware_product}{vendor} =
			$target_hardware->vendor->name;

		$location->{datacenter}{id}          = $datacenter->id;
		$location->{datacenter}{name}        = $datacenter->az;
		$location->{datacenter}{vendor_name} = $datacenter->vendor_name;
	}

	return $location;
}

sub _device_location {
	my ( $schema, $device_id ) = @_;
	my $device =
		$schema->resultset('DeviceLocation')->find( { device_id => $device_id } );
	return $device;
}

sub _get_rack {
	my ( $schema, $rack_id ) = @_;
	my $rack = $schema->resultset('DatacenterRack')
		->find( { id => $rack_id, deactivated => { '=', undef } } );
	return $rack;
}

sub _get_datacenter_room {
	my ( $schema, $room_id ) = @_;
	my $room = $schema->resultset('DatacenterRoom')->find( { id => $room_id } );
	return $room;
}

# get the hardware product a device should be by rack location
sub _get_target_hardware_product {
	my ( $schema, $rack_id, $rack_unit ) = @_;

	return $schema->resultset('HardwareProduct')->search(
		{
			'datacenter_rack_layouts.rack_id'  => $rack_id,
			'datacenter_rack_layouts.ru_start' => $rack_unit
		},
		{ join => 'datacenter_rack_layouts' }
	)->single;
}

sub _latest_device_report {
	my ( $schema, $device_id ) = @_;

	return $schema->resultset('LatestDeviceReport')
		->search( {}, { bind => [$device_id] } )->first;
}

# Bundle up the validate logs for a given device report.
sub _device_validation_report {
	my ( $schema, $report_id ) = @_;

	my @validate_report =
		$schema->resultset('DeviceValidate')->search( { report_id => $report_id } );

	my @reports;
	foreach my $r (@validate_report) {
		push @reports, decode_json( $r->validation );
	}

	return @reports;
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
