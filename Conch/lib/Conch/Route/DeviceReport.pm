package Conch::Route::DeviceReport;

use strict;
use Dancer2 appname => 'Conch';
use Hash::MultiValue;
use Conch::Control::DeviceReport;
set serializer => 'JSON';

prefix '/api' => sub {

  post '/device' => sub {
    record_device_report(
      parse_device_report(body_parameters->as_hashref)
    );
    return {status => "success"};
  };

};

1;
