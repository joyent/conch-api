package Test::Conch::Validation;
use strict;
use warnings;
use v5.26;
use experimental 'signatures';

use Test::More;
use Data::Printer; # for 'np'
use Test::Conch;
use Test::Warnings 'had_no_warnings';
use List::Util 'first';

use Exporter 'import';
our @EXPORT_OK = qw(test_validation);

=pod

=head1 NAME

Test::Conch::Validation - Test Conch Validations

=head1 EXPORTABLE FUNCTIONS

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
arguments specifying data to be made available to the Validation, and a keyword
argument specifying the cases for the test to use.

The only data made directly available to the validation is C<device>, so (most) data
should be nested underneath that, following the database schema.
For example:

    test_validation(
        'Conch::Validation::TestValidation',
        device => {
            asset_tag => 'foo',
            hardware_product => {
                name => 'Product Name',
                vendor => 'Product Vendor',
                cpu_num => 2,
            },
            device_location => {
                rack_unit_start => 2,
            },
            device_settings => {
                foo => 'bar'
            },
        },
        rack_layouts => [
            { rack_unit_start => 1 },
            { rack_unit_start => 2 },
            { rack_unit_start => 3 },
        ],

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

=item C<error_num>

The number of expected 'error' validation results from running the Validation
with the provided C<data>. Defaults to 0.

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

    my %fixtures = map +(exists $args{$_} ? ($_ => delete $args{$_}) : ()), qw(device rack_layouts);
    $fixtures{device} //= {};   # always create a device, even if generic

    my $cases = delete $args{cases};
    warn 'unsupported arguments: ', join(', ', keys %args) if keys %args;

    state $test_count = 0;
    subtest $test_count++.": $validation_module (".scalar($cases->@*).' cases)', sub {
        my $t = Test::Conch->new;

        use_ok($validation_module)
            || diag "$validation_module fails to compile" && return;

        my @objects = $t->generate_fixtures(%fixtures);

        my $device = first { $_->isa('Conch::DB::Result::Device') } @objects;

        # Note: we are not currently considering the case where both a device_location
        # and hardware_product are specified, and whether that hardware_product is different from
        # the device's hardware_product. No tests yet rely upon this assumption, but they should
        # so this should be fixed when DeviceProductName is rewritten and more sophisticated test
        # cases are written for it.

        my $validation = $validation_module->new(
            log => $t->app->log,
            device => $t->app->db_ro_devices->find($device->id),
        );

        for my $case_index (0 .. $cases->$#*) {
            my $case = $cases->[$case_index];
            subtest(
                join(': ', "Case $case_index", $case->{description}),
                \&_test_case => ($validation, $validation_module, $case));
        }

        had_no_warnings;
    };
}

sub _test_case {
    my ($validation, $validation_module, $case) = @_;
    my $data  = $case->{data} || {};
    my $debug = $case->{debug};

    my $msg_prefix = $case->{description} ? " [$case->{description}]: " : '';

    if ($debug) {
        my $pretty_data = substr(np($data), 2);
        diag($msg_prefix."input data: $pretty_data");
    }

    $validation->clear_results;

    $validation->run($data);

    my $success_count = scalar $validation->successes;
    my $success_expect = $case->{success_num} || 0;
    is($success_count, $success_expect,
            $msg_prefix.'Was expecting validation to register '
            ."$success_expect successful results, got $success_count.")
        or diag("\nSuccessful results:\n"._results_to_string($validation->successes));

    if ($debug and $success_count == $success_expect) {
        diag($msg_prefix."Successful results:\n"
            ._results_to_string($validation->successes));
    }

    my $failure_count = scalar $validation->failures;
    my $failure_expect = $case->{failure_num} || 0;

    is($failure_count, $failure_expect,
            $msg_prefix.'Was expecting validation to register '
            ."$failure_expect failing results, got $failure_count.")
        or diag("\nFailing results:\n"._results_to_string($validation->failures));
    if ($debug and $failure_count == $failure_expect) {
        diag($msg_prefix."Failing results:\n"
            ._results_to_string($validation->failures));
    }

    my $error_count = scalar $validation->error;
    my $error_expect = $case->{error_num} // ($success_expect + $failure_expect ? 0 : 1);
    is($error_count, $error_expect,
            $msg_prefix.'Was expecting validation to register '
            ."$error_expect error results, got $error_count.")
        or diag("\nError results:\n"._results_to_string($validation->error));
    if ($debug and $error_count == $error_expect) {
        diag($msg_prefix."Error results:\n"
            ._results_to_string($validation->error));
    }

    if (not Test::Builder->new->is_passing) {
        require Data::Dumper;
        diag 'all results: ',
            Data::Dumper->new([ [ $validation->validation_results ] ])->Indent(1)->Terse(1)->Dump;
    }
}

# Format the list of validation reusults into a single string, indented and
# with an incrementing list. Example output:
#
#    1. Expected eq 'foo', got 'foo'.
#    2. Expected == '1', got '1'.
#    3. Expected ne 'baz', got 'bar'.
sub _results_to_string (@results) {
    return "\tNone." unless @results;

    return join(
        "\n",
        map {
            my $i = $_ + 1;
            "\t$i. ".$results[$_]->{name}.': '.$results[$_]->{message}
            .($results[$_]->{hint} ? (' ('.$results[$_]->{hint}.')') : '')
        } (0 .. $#results)
    );
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
