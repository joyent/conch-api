package Conch::Route::DeviceReport;

use strict;
use Conch::Control::DeviceReport;
use Conch::Control::Device::Validation;
use Dancer2 appname => 'Conch';
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Hash::MultiValue;
set serializer => 'JSON';

prefix '/api' => sub {

  post '/device' => sub {
    #if (process sub {

        my $device = record_device_report(
            schema,
            parse_device_report(body_parameters->as_hashref)
          );
        validate_device(schema, $device);
       return {status => "success"};

      #}) { return {status => "success"}; }
    #else { return {status => "fail"}; }
  };

};

1;
