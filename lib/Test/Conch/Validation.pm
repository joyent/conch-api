package Test::Conch::Validation;
use strict;
use warnings;
use v5.26;

use Test::More;

use Conch::Log;
use Conch::Class::DatacenterRack;
use Conch::Class::DeviceLocation;
use Conch::Class::HardwareProduct;
use Conch::Class::HardwareProductProfile;

use Exporter 'import';
our @EXPORT_OK = qw( test_validation );

=pod

=head1 NAME

Test::Conch::Validation - Test Conch Validations

=head2 METHODS

=head2 test_validation

A function to test a Conch Validation using a collection of provided test cases.

This function performs the following tests:

=over

=item

Test whether the validation builds.

=item

Tests whether the validations defines the required C<name>, C<version>,
and C<description> attributes.

=back

The required arguments are the Conch Validation module as a string, keyword
arguments specifying optional models available to the Validation, and a keyword
argument specifying the cases for the test to use.

The available models are C<hardware_product>, C<device_location>,
C<device_settings>, and C<device>. Their attributes are defined with a hashref,
which will be constructed to the correct classes in the body of
L</test_validation>. For example:

	test_validation(
		'Conch::Validation::TestValidation',
		hardware_product => {
			name => 'Product Name',
			vendor => 'Product Vendor',
			profile => {
				num_cpu => 2
			}
		},
		device_location => {
			rack_unit       => 2,
			datacenter_rack => { slots => [ 1, 2, 3 ] }
		},
		device_settings => {
			foo => 'bar'
		},
		device => {
			triton_setup => 1,
		},

		cases => [ ... ]
	);

C<cases> is a list of hashrefs defining each of the test cases. Each case
specifies the input data and attributes representing the expected results. Each
test case may raise an error (die) or may produce 0 or more validation results.
A test case is specified with a hashref with the attributes:

=over

=item C<data>

A hashref of the input data provide to the Validation. An empty hashref will be provided by default.

=item C<success_num>

The number of expected successful validation results from running the
Validation with the provided C<data>. Defaults to 0.

=item C<failure_num>

The number of expected failing validation results from running the Validation
with the provided C<data>. Defaults to 0

=item C<description>

Optional description of the test case. Provides documentation and adds the
description to test failure messages.

=item C<debug>

Optional boolean flag to provide additional diagnostic information when running
the case using L<Test::More/diag>. This is helpful during development of test
cases, but should be removed before committing.

=back

Example:

	test_validation(
		'Conch::Validation::TestValidation',
		cases => [
			{
				data        => { hello => 'world' },
				success_num => 3,
				failure_num => 3,
				description => 'Hello world test case',
				debug       => 1
			}
		]
	);

=cut

sub test_validation {
	my $validation_module = shift;
	my %args              = @_;

	my $log = Conch::Log->new(path => 'log/development.log');

	use_ok($validation_module)
		|| diag "$validation_module fails to compile" && return;

	my $device = $args{device} ? Conch::Model::Device->new($args{device}) : undef;

	my $hw_product_profile =
		  $args{hardware_product} && $args{hardware_product}->{profile}
		? Conch::Class::HardwareProductProfile->new($args{hardware_product}->{profile}->%*)
		: undef;

	my $hw_product = Conch::Class::HardwareProduct->new(
		$args{hardware_product}->%*,
		profile => $hw_product_profile,
	);

	my $rack =
		  $args{device_location} && $args{device_location}{datacenter_rack}
		? Conch::Class::DatacenterRack->new($args{device_location}->{datacenter_rack}->%*)
		: undef;

	my $device_location = Conch::Class::DeviceLocation->new(
		$args{device_location}->%*,
		datacenter_rack => $rack,
	);

	my $validation = $validation_module->new(
		device           => $device,            # this is a Conch::Model::Device
		device_location  => $device_location,   # this is a Conch::Class::DeviceLocation
		device_settings  => $args{device_settings} || {},
		hardware_product => $hw_product,        # this is a Conch::Class::HardwareProduct
	);
	$validation->log($log);
	isa_ok( $validation, $validation_module, "$validation_module->new failed" )
		|| return;

	ok(
		defined( $validation->name ),
		"'name' attribute must be defined for $validation_module"
	);

	ok(
		defined( $validation->version ),
		"'version' attribute must be defined for $validation_module"
	);

	ok(
		defined( $validation->category ),
		"'category' attribute should be defined for $validation_module"
	);

	ok(
		defined( $validation->description ),
		"'description' attribute should be defined for $validation_module"
	);

	for my $case_index ( 0 .. $args{cases}->$#* ) {
		_test_case( $validation, $validation_module, $args{cases}, $case_index );
	}
}

sub _test_case {
	my ( $validation, $validation_module, $cases, $case_index ) = @_;
	my $case  = $cases->[$case_index];
	my $data  = $case->{data} || {};
	my $debug = $case->{debug};

	my $msg_prefix = 'Case #' . ( $case_index + 1 );
	$msg_prefix .= $case->{description} ? ' [' . $case->{description} . ']:' : ':';

	if ($debug) {
		my $pretty_data = substr( np($data), 2 );
		diag("$msg_prefix input data: $pretty_data");
	}

	$validation->clear_results;

	$validation->run($data);

	if ($debug) {
		diag( "$msg_prefix Successful results:\n"
				. _results_to_string( $validation->successes ) );
		diag( "$msg_prefix Failing results:\n"
				. _results_to_string( $validation->failures ) );
	}

	my $success_count = scalar $validation->successes->@*;
	my $success_expect = $case->{success_num} || 0;
	is( $success_count, $success_expect,
		    "$msg_prefix Was expecting validation to register "
			. "$success_expect successful results, got $success_count."
			. "\nSuccessful results:\n"
			. _results_to_string( $validation->successes ) );

	my $failure_count = scalar $validation->failures->@*;
	my $failure_expect = $case->{failure_num} || 0;

	is( $failure_count, $failure_expect,
		    "$msg_prefix Was expecting validation to register "
			. "$failure_expect failing results, got $failure_count."
			. "\nFailing results:\n"
			. _results_to_string( $validation->failures ) );
}

# Format the list of validation reusults into a single string, indented and
# with an incrementing list. Example output:
#
#	1. Expected eq 'foo', got 'foo'.
#	2. Expected == '1', got '1'.
#	3. Expected ne 'baz', got 'bar'.
sub _results_to_string ($) {
	my $results = shift;
	return "\tNone." unless $results->@*;

	return join(
		"\n",
		map {
			my $i = $_ + 1;
			"\t$i. " . $results->[$_]->{name} . ': ' . $results->[$_]->{message}
		} ( 0 .. $results->$#* )
	);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
