package Conch::UUID;

use Mojo::Base -strict, -signatures;
use Data::UUID ();
use Exporter 'import';
our @EXPORT_OK = qw(is_uuid create_uuid_str);

use constant UUID_FORMAT_LAX => qr/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/ia;
use constant UUID_FORMAT => qr/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/a;

=pod

=head1 NAME

Conch::UUID - Functions for working with UUIDs in Conch

=head1 SYNOPSIS

    use Conch::UUID 'is_uuid';

=head1 DESCRIPTION

Currently exports a single function, C<is_uuid>, to determine whether a string
is in the UUID format. It uses the format specified in RFC 4122
https://tools.ietf.org/html/rfc4122#section-3

      UUID                   = time-low "-" time-mid "-"
                               time-high-and-version "-"
                               clock-seq-and-reserved
                               clock-seq-low "-" node
      time-low               = 4hexOctet
      time-mid               = 2hexOctet
      time-high-and-version  = 2hexOctet
      clock-seq-and-reserved = hexOctet
      clock-seq-low          = hexOctet
      node                   = 6hexOctet
      hexOctet               = hexDigit hexDigit
      hexDigit =
            "0" / "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9" /
            "a" / "b" / "c" / "d" / "e" / "f" /
            "A" / "B" / "C" / "D" / "E" / "F"

UUID version and variant ('reserved') hex digit standards are ignored.

=head1 FUNCTIONS

=head2 is_uuid

Return a true or false value based on whether a string is a formatted as a UUID.

    if (is_uuid('D8DC809C-935E-41B8-9E5F-B356A6BFBCA1')) {...}
    if (not is_uuid('BAD-ID')) {...}

Case insensitive, as per RFC4122 (output characters are lower-cased, but characters are
case insensitive on input.)

=cut

sub is_uuid ($uuid) {
    return ($uuid =~ qr/^${\UUID_FORMAT_LAX}$/);
}

=head2 create_uuid_str

Returns a newly-generated rfc4122-compliant uuid string.

=cut

sub create_uuid_str () {
    # TODO: switch to Data::GUID
    Data::UUID->new->create_str =~ tr/A-Z/a-z/r;
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
