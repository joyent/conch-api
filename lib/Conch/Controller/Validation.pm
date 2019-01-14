package Conch::Controller::Validation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Conch::UUID 'is_uuid';

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

=head2 find_validation

Find the Validation specified by uuid or name and put it in the stash as
C<validation>.

=cut

sub find_validation($c) {
    my $identifier = $c->stash('validation_id_or_name');

    my $validation = $c->db_validations->active->search({
        (is_uuid($identifier) ? 'id' : 'name') => $identifier,
    })->single;

    if (not $validation) {
        $c->log->debug("Failed to find validation for '$identifier'");
        return $c->status(404, { error => 'Not found' });
    }

    $c->log->debug('Found validation '.$validation->id);
    $c->stash(validation => $validation);
    return 1;
}

=head2 get

Get the Validation specified by uuid or name.

Response uses the Validation json schema.

=cut

sub get ($c) {
    return $c->status(200, $c->stash('validation'));
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
