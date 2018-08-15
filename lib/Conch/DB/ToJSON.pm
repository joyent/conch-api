package Conch::DB::ToJSON;
use v5.26;
use warnings;

use parent 'DBIx::Class::Helper::Row::ToJSON';

=head1 NAME

Conch::DB::ToJSON

=head1 DESCRIPTION

A component for Conch::DB::Result classes to provide serialization functionality via C<TO_JSON>.
Sub-classes L<DBIx::Class::Helper::Row::ToJSON> to also serialize 'text' data.

=head1 USAGE

    __PACKAGE__->load_components('+Conch::DB::ToJSON');

=cut

# same as parent, only 'text' is not unserializable.
sub unserializable_data_types {
    return {
        blob  => 1,
        ntext => 1,
    };
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
