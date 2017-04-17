package Conch::Controller::Validate::Environment;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use Data::Printer;

=head1 NAME

Conch::Controller::Validate::Environment - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Conch::Controller::Validate::Environment in Validate::Environment.');

    $c->forward('cpu_temp');
    $c->forward('disk_temp');
}
 
sub cpu_temp : Private {
  my ( $self, $c ) = @_;
    
  my $device_id = lc($c->req->data->{system_uuid});
  $c->log->debug("$device_id: Validating CPU temps");

  my $device_env = $c->model('DB::DeviceEnvironment')->search({
    device_id => $device_id,
  }, {
    order_by  => 'updated'
  })->single;

  my $criteria = $c->model('DB::DeviceValidateCriteria')->search({
    component  => "CPU",
    condition => "temp"
  })->single;

  # XXX This should be aware of cpu_num, but for now, whatever.
  foreach my $cpu (qw/cpu0 cpu1/) {
    $c->log->debug("$device_id: validating $cpu temp");
    my $cpu_msg;
    my $cpu_status;

    my $method = "${cpu}_temp";

    if ( $device_env->$method > $criteria->crit ) {
      $cpu_msg = "$device_id: CRITICAL: $cpu: " . $device_env->$method . " (>". $criteria->crit .")";
      $cpu_status = 0;
     } elsif ( $device_env->$method > $criteria->warn ) {
       $cpu_msg = "$device_id: WARNING: $cpu: " . $device_env->$method . " (>". $criteria->warn .")";
       $cpu_status = 0;
     } else {
       $cpu_msg = "$device_id: OK: $cpu: " . $device_env->$method . " (<". $criteria->warn .")";
       $cpu_status = 1;
     }

     $c->log->debug($cpu_msg);

     my $device_validate = $c->model('DB::DeviceValidate')->update_or_create({
       device_id       => $device_id, 
       component_type  => "CPU",
       component_name  => $cpu,
       criteria_id     => $criteria->id,
       metric          => $device_env->$method,
       log             => $cpu_msg,
       status          => $cpu_status,
     });
  }
}

sub disk_temp : Private {
  my ( $self, $c ) = @_;
  my $device_id = lc($c->req->data->{system_uuid});
  $c->log->debug("$device_id: Validating Disk temps");

  my $criteria_sas = $c->model('DB::DeviceValidateCriteria')->search({
    component  => "SAS_HDD",
    condition  => "temp"
  })->single;

  my $criteria_ssd = $c->model('DB::DeviceValidateCriteria')->search({
    component  => "SAS_SSD",
    condition  => "temp"
  })->single;

  my $disks = $c->model('DB::DeviceDisk')->search({
    device_id   => $device_id,
    deactivated => { '=', undef },
    transport   => { '!=', "usb" } # No temps for USB devices.
  });

  while ( my $disk = $disks->next ) {
    $c->log->debug($disk->id . ": ". $disk->serial_number . ": validating temps");
   
    my $crit;
    my $warn;
    my $disk_msg;
    my $disk_status;
    my $criteria_id;

    if ( $disk->drive_type eq "SAS_HDD" ) {
      $crit = $criteria_sas->crit;
      $warn = $criteria_sas->warn;
      $criteria_id = $criteria_sas->id;
    }

    if ( $disk->drive_type eq "SAS_SSD" ) {
      $crit = $criteria_ssd->crit;
      $warn = $criteria_ssd->warn;
      $criteria_id = $criteria_ssd->id;
    }

    if ( $disk->temp > $crit ) {
      $disk_msg = "CRITICAL: " . $disk->serial_number . ": " . $disk->temp. " (>". $crit .")";
      $disk_status = 0;
     } elsif ( $disk->temp > $warn ) {
       $disk_msg = "WARNING: " . $disk->serial_number . ": " . $disk->temp . " (>". $warn .")";
       $disk_status = 0;
     } else {
       $disk_msg = "OK: " . $disk->serial_number . ": " . $disk->temp . " (<". $warn .")";
       $disk_status = 1;
     }

     $c->log->debug($disk->id . ": ". $disk->serial_number . ": " . $disk_msg);

     my $device_validate = $c->model('DB::DeviceValidate')->update_or_create({
       device_id       => $device_id, 
       component_type  => $disk->drive_type,
       component_name  => $disk->serial_number,
       component_id    => $disk->id,
       criteria_id     => $criteria_id,
       metric          => $disk->temp,
       log             => $disk_msg,
       status          => $disk_status,
     });
  }
}

sub inlet_temp : Private {
  my ( $self, $c ) = @_;
}

sub exhaust_temp : Private {
  my ( $self, $c ) = @_;
}

=encoding utf8

=head1 AUTHOR

Super-User

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
