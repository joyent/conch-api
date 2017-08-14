package Conch::Control::Device::Profile;

use v5.10;
use strict;
use List::Compare;
use Log::Report;
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( determine_product );


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
