=pod

=head1 NAME

Conch::Models

=head1 DESCRIPTION

Convenience class to load all the Conch::Model classes

=cut

package Conch::Models;
use v5.20;
use warnings;

use Conch::DB;

use Conch::Model::Datacenter;
use Conch::Model::DatacenterRoom;
use Conch::Model::DatacenterRackRole;
use Conch::Model::DatacenterRack;
use Conch::Model::DatacenterRackLayout;

use Conch::Model::DeviceLocation;
use Conch::Model::DeviceSettings;
use Conch::Model::HardwareProduct;
use Conch::Model::Relay;
use Conch::Model::Validation;
use Conch::Model::ValidationPlan;
use Conch::Model::ValidationState;
use Conch::Model::WorkspaceRack;
use Conch::Model::WorkspaceRelay;
use Conch::Model::WorkspaceRoom;

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
