package Conch::DB::ResultSet;
use v5.26;
use warnings;
use parent 'DBIx::Class::ResultSet';

=head1 NAME

Conch::DB::ResultSet

=head1 DESCRIPTION

Base class for our resultsets, to allow us to add on additional functionality from what is
available in core DBIx::Class.

=cut

__PACKAGE__->load_components(
    '+Conch::DB::Deactivatable',    # provides active, deactivate
);

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
