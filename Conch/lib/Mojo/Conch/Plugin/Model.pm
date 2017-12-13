package Mojo::Conch::Plugin::Model;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Mojo::Conch::Model::Device;
use Mojo::Conch::Model::DeviceLocation;
use Mojo::Conch::Model::DeviceReport;
use Mojo::Conch::Model::DeviceSettings;
use Mojo::Conch::Model::HardwareProduct;
use Mojo::Conch::Model::Relay;
use Mojo::Conch::Model::User;
use Mojo::Conch::Model::UserSettings;
use Mojo::Conch::Model::Workspace;
use Mojo::Conch::Model::WorkspaceDevice;
use Mojo::Conch::Model::WorkspaceRack;
use Mojo::Conch::Model::WorkspaceRelay;
use Mojo::Conch::Model::WorkspaceRoom;
use Mojo::Conch::Model::WorkspaceUser;

# Setup Conch Models for production
sub register ($self, $app, $conf) {

  $app->helper(
    device => sub {
      state $device = Mojo::Conch::Model::Device->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    device_location => sub {
      state $device_location = Mojo::Conch::Model::DeviceLocation->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    device_report => sub {
      state $device_report = Mojo::Conch::Model::DeviceReport->new(
        pg => $app->pg,
        log => $app->log
      )
    }
  );
  $app->helper(
    device_settings => sub {
      state $device_settings = Mojo::Conch::Model::DeviceSettings->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    hardware_product => sub {
      state $hardware_product = Mojo::Conch::Model::HardwareProduct->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    relay => sub {
      state $relay = Mojo::Conch::Model::Relay->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    user => sub {
      state $user = Mojo::Conch::Model::User->new(
        pg => $app->pg,
        hash_password => sub { $app->bcrypt(@_)},
        validate_against_hash => sub { $app->bcrypt_validate(@_)}
      )
    }
  );
  $app->helper(
    user_settings => sub {
      state $user_settings = Mojo::Conch::Model::UserSettings->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    workspace => sub {
      state $workspace = Mojo::Conch::Model::Workspace->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    workspace_device => sub {
      state $workspace_device = Mojo::Conch::Model::WorkspaceDevice->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    workspace_rack => sub {
      state $workspace_rack = Mojo::Conch::Model::WorkspaceRack->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    workspace_relay => sub {
      state $workspace_relay = Mojo::Conch::Model::WorkspaceRelay->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    workspace_room => sub {
      state $workspace_room = Mojo::Conch::Model::WorkspaceRoom->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    workspace_user => sub {
      state $workspace_user = Mojo::Conch::Model::WorkspaceUser->new(
        pg => $app->pg
      )
    }
  );
  $app->helper(
    role => sub {
      state $workspace_role = Mojo::Conch::Model::WorkspaceRole->new(
        pg => $app->pg
      )
    }
  );

}

1;
