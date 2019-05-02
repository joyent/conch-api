=pod

=head1 NAME

Conch::ValidationError - Internal error representation for L<Conch::Validation>

=head1 DESCRIPTION

Extends 'Mojo::Exception' to store a 'hint' attribute. Intended for use in
L<Conch::Validation>.

=head1 METHODS

=cut

package Conch::ValidationError;

use Mojo::Base 'Mojo::Exception';
has 'hint';

=head2 error_loc

Return a description of where the error occurred. Provides the module name and
line number, but not the filepath, so it doesn't expose where the file lives.

=cut

sub error_loc {
    my $frame = shift->frames->[0];

    my $error_loc = 'Exception raised in \''.$frame->[0].'\' at line '.$frame->[2];
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
