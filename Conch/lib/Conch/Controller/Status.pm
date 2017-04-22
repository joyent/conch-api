package Conch::Controller::Status;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use Data::Printer;

=head1 NAME

Conch::Controller::Status - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  $c->forward('status');
}

sub status : Local {
  my ( $self, $c ) = @_;

  my @devices = $c->model('DB::Device')->all;
  my $device_count = scalar(@devices);

  my @reporting_devices = $c->model('DB::Device')->search({
    last_seen => \' > NOW() - INTERVAL \'2 minutes\'',
  });

  my $reporting_count;
  if ( @reporting_devices ) {
    $reporting_count = scalar(@reporting_devices);
    $c->stash(reporting_devices => \@reporting_devices);
    $c->stash(reporting_count => $reporting_count);
  }

  my @missing_devices = $c->model('DB::Device')->search({
    triton_setup => "false",
    triton_uuid => { '=', undef },
    graduated => { '!=', undef },
    health => 'PASS',
  });

  my $missing_count;
  if ( @missing_devices ) {
    $missing_count = scalar(@missing_devices);
    $c->stash(missing_devices => \@missing_devices);
    $c->stash(missing_count => $missing_count);
  }

  my @ready_devices = $c->model('DB::Device')->search({
    triton_setup => "false",
    graduated => { '=', undef },
    health => 'PASS',
  });

  my $ready_count;
  if ( @ready_devices ) {
    $ready_count = scalar(@ready_devices);
    $c->stash(ready_devices => \@ready_devices);
    $c->stash(ready_count => $ready_count);
  }

  my @triton_pending_devices = $c->model('DB::Device')->search({
    triton_setup => "false",
    triton_uuid => { '!=', undef },
  });

  my $triton_pending_count;
  if ( @triton_pending_devices ) {
    $triton_pending_count = scalar(@triton_pending_devices);
    $c->stash(triton_pending_devices => \@triton_pending_devices);
    $c->stash(triton_pending_count => $triton_pending_count);
  }

  my @triton_devices = $c->model('DB::Device')->search({
    triton_setup => "true",
  });

  my $triton_count;
  if ( @triton_devices ) {
    $triton_count = scalar(@triton_devices);
    $c->stash(triton_devices => \@triton_devices);
    $c->stash(triton_count => $triton_count);
  }

  my @graduated_devices = $c->model('DB::Device')->search({
    graduated => { '!=', undef },
  });

  my $graduated_count;
  if ( @graduated_devices ) {
    $graduated_count = scalar(@graduated_devices);
    $c->stash(graduated_devices => \@graduated_devices);
    $c->stash(graduated_count => $graduated_count);
  }

  my @passing_devices = $c->model('DB::Device')->search({
    health => "PASS"
  });

  my $passing_count;
  if ( @passing_devices ) {
    $passing_count = scalar(@passing_devices);
    $c->stash(passing_devices => \@passing_devices);
    $c->stash(passing_count => $passing_count);
  }

  my @failing_devices = $c->model('DB::Device')->search({
    health => "FAIL"
  });

  my $failing_count;
  if ( @failing_devices ) {
    $failing_count = scalar(@failing_devices);
    $c->stash(failing_devices => \@failing_devices);
    $c->stash(failing_count => $failing_count);
  }

  my @unknown_devices = $c->model('DB::Device')->search({
    health => "UNKNOWN"
  });

  my $unknown_count;
  if ( @unknown_devices ) {
    $unknown_count = scalar(@unknown_devices);
    $c->stash(unknown_devices => \@unknown_devices);
    $c->stash(unknown_count => $unknown_count);
  }

  $c->stash(devices => [$c->model('DB::Device')->all]);
  $c->stash(device_count => $device_count);
  $c->stash(template => 'status.tt2');

  $c->forward('View::HTML');
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
