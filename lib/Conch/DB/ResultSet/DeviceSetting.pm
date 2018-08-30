package Conch::DB::ResultSet::DeviceSetting;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use List::Util 'pairmap';

=head1 NAME

Conch::DB::ResultSet::DeviceSetting

=head1 DESCRIPTION

Interface to queries involving device settings.

=head1 METHODS

=head2 get_settings

Retrieve all active settings for a device as a hash.

=cut

sub get_settings {
    my $self = shift;

    # turn device_setting db rows into name => value entries,
    # with newer entries overwriting older ones
    return map {
        $_->name => $_->value
    } $self->search(undef, { order_by => 'created' })->active;
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
# vim: set ts=4 sts=4 sw=4 et :
