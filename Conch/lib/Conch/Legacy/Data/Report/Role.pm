package Conch::Legacy::Data::Report::Role;

use strict;
use Moose::Role;

# 'validations' should give a array of validation functions.  All of the
# validation functions to run validation function should have the following
# signature: `my ($schema, $device, $report_id) = @_;`
requires qw( validations );

1;
