package Conch::DB::Result;
use v5.26;
use warnings;
use parent 'DBIx::Class::Core';

=head1 NAME

Conch::DB::Result

=head1 DESCRIPTION

Base class for our result classes, to allow us to add on additional functionality from what is
available in core L<DBIx::Class>.

=head1 METHODS

Methods added are:

=over 4

=item * L<self_rs|DBIx::Class::Helper::Row::SelfResultSet/self_rs>

=item * L<TO_JSON|Conch::DB::Helper::Row::ToJSON>

=back

=cut

__PACKAGE__->load_components(
    '+Conch::DB::InflateColumn::Time',  # inflates 'timestamp with time zone' columns to Conch::Time
    '+Conch::DB::Helper::Row::ToJSON',  # provides serialization hooks
    'Helper::Row::SelfResultSet',       # provides self_rs
);

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
