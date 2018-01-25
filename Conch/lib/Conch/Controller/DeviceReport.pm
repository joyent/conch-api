package Conch::Controller::DeviceReport;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';
use Storable 'dclone';

use Try::Tiny;

use Conch::Legacy::Schema;
use Conch::Legacy::Control::DeviceReport 'record_device_report';
use Conch::Legacy::Control::Device::Validation 'validate_device';
use Conch::Legacy::Data::Report::Switch;
use Conch::Legacy::Data::Report::Server;

# TODO: None of the available Mojolicious Log4Perl libraries allow selecting
# the category (appender) for Log4Perl. We use this mechanism to log unparsable
# device reports and device reports that result in processing exceptions
sub process ($c) {
	my $raw_report = $c->req->json;

	#Log::Any->get_logger( category => 'report.raw' )
	#->trace( encode_json $raw_report);
	my $device_report;
	try {
		if ( $raw_report->{device_type} && $raw_report->{device_type} eq "switch" )
		{
			$device_report = Conch::Legacy::Data::Report::Switch->new($raw_report);
		}
		else {
			$device_report = Conch::Legacy::Data::Report::Server->new($raw_report);
		}
	}
	catch {
		my $errs = join( "; ", map { $_->message } $device_report->errors );

		$c->app->log->error( 'Failed parsing device report: ' . $errs );

		return $c->status( 400, { error => $errs } );
	};

	my $aux_report = dclone($raw_report);
	for my $attr ( keys %{ $device_report->pack } ) {
		delete $aux_report->{$attr};
	}
	if ( %{$aux_report} ) {
		$device_report->{aux} = $aux_report;
	}

	my $hw_product_name = $device_report->{product_name};
	my $maybe_hw        = $c->hardware_product->lookup_by_name($hw_product_name);

	unless ($maybe_hw) {
		return $c->status(
			409,
			{
				error => "Hardware Product '$hw_product_name' does not exist."
			}
		);
	}

	# Use the old device report recording and device validation code for now.
	# This will be removed when OPS-RFD 22 is implemented
	my $schema = Conch::Legacy::Schema->connect( $c->pg->dsn, $c->pg->username,
		$c->pg->password );

	my ( $device, $report_id ) = record_device_report( $schema, $device_report );
	my $validation_result =
		validate_device( $schema, $device, $device_report, $report_id );

	$c->status( 200, $validation_result );
}

1;
