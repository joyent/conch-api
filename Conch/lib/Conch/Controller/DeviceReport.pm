package Conch::Controller::DeviceReport;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';
use Attempt qw(try);
use Storable 'dclone';

use Conch::Legacy::Schema;
use Conch::Legacy::Control::DeviceReport 'record_device_report';
use Conch::Legacy::Control::Device::Validation 'validate_device';
use Conch::Legacy::Data::Report::Switch;
use Conch::Legacy::Data::Report::Server;

# TODO: None of the available Mojolicious Log4Perl libraries allow selecting
# the category (appender) for Log4Perl. We used this mechanism to log unparsable
# device reports and device reports that result in processing exceptions.
sub process ($c) {
	my $raw_report = $c->req->json;

	#Log::Any->get_logger( category => 'report.raw' )
	#->trace( encode_json $raw_report);
	my $device_report = $c->_parse_device_report($raw_report);

	if ( $device_report->is_fail ) {

		#my $err_log = Log::Any->get_logger( category => 'report.unparsable' );
		$c->app->log->error(
			'Failed parsing device report: ' . $device_report->failure );
		return $c->status( 400, { error => $device_report->failure } );
	}

	# Use the old device report recording and device validation code for now.
	# This will be removed when OPS-RFD 22 is implemented
	my $schema = Conch::Legacy::Schema->connect( $c->pg->dsn, $c->pg->username,
		$c->pg->password );

	my ( $device, $report_id ) =
		record_device_report( $schema, $device_report->value );
	my $validation_result =
		validate_device( $schema, $device, $device_report->value, $report_id );

	$c->status( 200, $validation_result );
}

# Parse a report object from a HashRef and report all validation errors
# Returns a list where the first element may be the parsed log and the second
# may be validation errors, but not both.
sub _parse_device_report ( $self, $input ) {
	my $aux_report = dclone($input);

	my $report;
	if ( $input->{device_type} && $input->{device_type} eq "switch" ) {
		$report = try { Conch::Legacy::Data::Report::Switch->new($input) };
	}
	else {
		$report = try { Conch::Legacy::Data::Report::Server->new($input) };
	}

	if ( $report->is_fail ) {
		my $errs = join( "; ", map { $_->message } $report->failure->errors );
		$self->log->warn("Error validating device report: $errs");
		return fail($errs);
	}
	else {
		for my $attr ( keys %{ $report->value->pack } ) {
			delete $aux_report->{$attr};
		}
		if ( %{$aux_report} ) {
			$report->value->{aux} = $aux_report;
		}
		return $report;
	}
}

1;
