package Mojo::Conch::Controller::DeviceReport;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';

use Conch::Schema;
use Conch::Control::DeviceReport 'record_device_report';
use Conch::Control::Device::Validation 'validate_device';


# TODO: None of the available Mojolicious Log4Perl libraries allow selecting
# the category (appender) for Log4Perl. We use this mechanism to log unparsable
# device reports and device reports that result in processing exceptions
sub process ($c) {
  my $raw_report = $c->req->json;
  #Log::Any->get_logger( category => 'report.raw' )
    #->trace( encode_json $raw_report);
  my $device_report = $c->device_report->parse_device_report($raw_report);

  if ($device_report->is_fail) {
    #my $err_log = Log::Any->get_logger( category => 'report.unparsable' );
    $c->log->error('Failed parsing device report: '  .$device_report->failure );
    $c->log->trace( $raw_report );
    return $c->status(400, { error => $device_report->failure });
  }

  # Use the old device report recording and device validation code for now.
  # This will be removed when OPS-RFD 22 is implemented
  my $schema = Conch::Schema->connect(
    $c->pg->dsn,
    $c->pg->username,
    $c->pg->password
  );

  my ($device, $report_id) = record_device_report($schema, $device_report->value);
  my $validation_result = validate_device($schema, $device, $device_report->value, $report_id);

  $c->status(200, $validation_result);
}

1;

