package Conch::Legacy::Data::Report::Role;

use strict;
use Moose::Role;

# 'validations' should give a array of validation functions.  All of the
# validation functions to run validation function should have the following
# signature: `my ($schema, $device, $report_id) = @_;`
requires qw( validations );

1;


__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

