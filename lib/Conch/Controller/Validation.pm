=pod

=head1 NAME

Conch::Controller::Validation

Controller for managing Validations, B<NOT> executing them.

=head1 METHODS

=cut

package Conch::Controller::Validation;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::Models;

=head2 list

List all available Validations

=cut

sub list ($c) {
	my $validations = Conch::Model::Validation->list;

	$c->status( 200, $validations );
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
