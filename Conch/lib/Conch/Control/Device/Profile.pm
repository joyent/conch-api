package Conch::Control::Device::Profile;

use v5.10;
use strict;
use List::Compare;
use Log::Report mode => 'DEBUG';
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( determine_product set_device_settings get_device_settings );


sub set_device_settings {
  my ($schema, $device, $settings) = @_;

  my @hardware_settings =
    $device
    ->hardware_product
    ->hardware_product_profile
    ->hardware_profile_settings
    ->all;

  my $setting_keys = {};
  for my $hardware_setting (@hardware_settings) {
    $setting_keys->{$hardware_setting->name} = $hardware_setting->id;
  }

  # Find all invalid keys in the request
  try {
    for my $setting_name (keys %{$settings}) {
      mistake $setting_name unless $setting_keys->{$setting_name};
    }
  } acccept => 'ERROR';

  if ($@->exceptions > 0) {
      my @bad_names = map { $_->message } $@->exceptions;
      error("No hardware product setting for following keys: @bad_names");
  }

  $schema->txn_do (sub {

    for my $setting (keys %{$settings}) {
      my $resource_id = $setting_keys->{$setting};
      my $value = $settings->{$setting};

      my $prev_setting =
        $device->device_settings
        ->search({resource_id => $resource_id, deactivated => undef})
        ->single;
      $prev_setting->update({ deactivated => \'NOW()' }) if $prev_setting;
      $device->device_settings->create({
          device_id => $device->id,
          resource_id => $resource_id,
          value => $value
      });
    }

  });

  return { status => "updated settings for " . $device->id };
}

sub get_device_settings {

  my ($schema, $device) = @_;

  my @hardware_settings =
    $device
    ->hardware_product
    ->hardware_product_profile
    ->hardware_profile_settings
    ->all;

  my $setting_id_to_names = {};
  for my $hardware_setting (@hardware_settings) {
    $setting_id_to_names->{$hardware_setting->id} = $hardware_setting->name;
  }

  my @resource_ids = keys %{$setting_id_to_names};
  my @device_settings = $device->device_settings->search({
        resource_id => { 'in' => @resource_ids },
        deactivated => undef
      })->all;

  my $res = {};
  for my $setting (@device_settings) {
    $res->{$setting_id_to_names->{$setting->resource_id}} = $setting->value;
  }
  return $res;
}

# XXX We should use 'hardware_product_profile' to determine the these details
sub determine_product {
  my ($schema, $serial, $profile) = @_;

  my $product = {};

  # Determine vendor
  if ($profile->{vendor} =~ /dell/i) {
    $product->{vendor} = "dell";
  }
  elsif ($profile->{vendor} =~ /supermicro/i) {
    $product->{vendor} = "smci";
  }
  else {
    if (length($serial) == 7) {
      $product->{vendor} = "dell";
    }
    elsif (length($serial) == 7) {
      $product->{vendor} = "smci";
    }
    else {
      warning "Unable to determine product vendor";
      $product->{vendor} = "UNKNOWN";
    }
  }

  for($product->{vendor}) {

    when(/dell/) {
      for($profile->{disk_count}) {
        if ($_ == 12) {
          $product->{model} = "type1-ceres";
        }
        elsif ($_ == 15) {
          $product->{model} = "jcp-3301";
        }
        elsif ($_ == 8 || $_ == 16) {
          $product->{model} = "jcp-3302";
        }

        # Possible disk failures, fallback
        else {
          if ($profile->{mb_string} eq "072T6D") {
             $product->{model} = "hallasan";
          }
          else {
            warning "Unable to determine Dell model";
            $product->{model} = "UNKNOWN";
          }
       }
      }
    }

    when(/smci/) {
      if ($profile->{disk_count} == 35) {
        $product->{model} = "jsp-7001";
      }

      # Possible disk failures, fallback
      else {
        if ($profile->{mb_string} eq "X10DRH-iT") {
          $product->{model} = "jsp-7001";
        }
        else {
            warning "Unable to determine SMCI model";
            $product->{model} = "UNKNOWN";
        }
      }
    }

    default {
      warning "Unable to determine model for vendor $product->{vendor}";
      $product->{model} = "UNKNOWN";
    }
  }

  return $product;
}


1;
