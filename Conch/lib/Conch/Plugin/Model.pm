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
use Conch::Model::WorkspaceRole;


=head2 register

Sets up Mojo helpers for all the models

=cut

sub register ( $self, $app, $conf ) {
	$app->helper(
		workspace_user => sub {
			state $workspace_user =
				Conch::Model::WorkspaceUser->new();
		}
	);
	$app->helper(
		role => sub {
			state $workspace_role =
				Conch::Model::WorkspaceRole->new();
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

