=pod

=head1 NAME

Conch::Plugin::Model

=head1 METHODS

=cut

package Conch::Plugin::Model;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Conch::Model::DeviceLocation;
use Conch::Model::DeviceReport;
use Conch::Model::DeviceSettings;
use Conch::Model::HardwareProduct;
use Conch::Model::Relay;
use Conch::Model::Workspace;
use Conch::Model::WorkspaceDevice;
use Conch::Model::WorkspaceRack;
use Conch::Model::WorkspaceRelay;
use Conch::Model::WorkspaceRoom;
use Conch::Model::WorkspaceUser;



=head2 register

Sets up Mojo helpers for all the models

=cut

sub register ( $self, $app, $conf ) {
	$app->helper(
		device_location => sub {
			state $device_location =
				Conch::Model::DeviceLocation->new( pg => $app->pg );
		}
	);
	$app->helper(
		device_report => sub {
			state $device_report = Conch::Model::DeviceReport->new(
				pg  => $app->pg,
				log => $app->log
			);
		}
	);
	$app->helper(
		device_settings => sub {
			state $device_settings =
				Conch::Model::DeviceSettings->new( pg => $app->pg );
		}
	);
	$app->helper(
		hardware_product => sub {
			state $hardware_product =
				Conch::Model::HardwareProduct->new( pg => $app->pg );
		}
	);
	$app->helper(
		relay => sub {
			state $relay = Conch::Model::Relay->new( pg => $app->pg );
		}
	);
	$app->helper(
		workspace => sub {
			state $workspace = Conch::Model::Workspace->new( pg => $app->pg );
		}
	);
	$app->helper(
		workspace_device => sub {
			state $workspace_device =
				Conch::Model::WorkspaceDevice->new( pg => $app->pg );
		}
	);
	$app->helper(
		workspace_rack => sub {
			state $workspace_rack =
				Conch::Model::WorkspaceRack->new( pg => $app->pg );
		}
	);
	$app->helper(
		workspace_relay => sub {
			state $workspace_relay =
				Conch::Model::WorkspaceRelay->new( pg => $app->pg );
		}
	);
	$app->helper(
		workspace_room => sub {
			state $workspace_room =
				Conch::Model::WorkspaceRoom->new( pg => $app->pg );
		}
	);
	$app->helper(
		workspace_user => sub {
			state $workspace_user =
				Conch::Model::WorkspaceUser->new( pg => $app->pg );
		}
	);
	$app->helper(
		role => sub {
			state $workspace_role =
				Conch::Model::WorkspaceRole->new( pg => $app->pg );
		}
	);

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

