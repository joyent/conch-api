package Conch::Controller::Validation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

=pod

=head1 NAME

Conch::Controller::Validation

Controller for managing Validations, B<NOT> executing them.

=head1 METHODS

=head2 list

List all available Validations.

Response uses the Validations json schema.

=cut

sub list ($c) {
    my @validations = $c->db_validations->active->all;

    $c->status(200, \@validations);
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
