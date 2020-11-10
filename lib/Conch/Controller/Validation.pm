package Conch::Controller::Validation;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::Validation

Controller for managing Validations, B<NOT> executing them.

=head1 METHODS

=head2 get_all

List all Validations.

Response uses the LegacyValidations json schema (including deactivated ones).

=cut

sub get_all ($c) {
    my $rs = $c->db_validations->order_by([ qw(name version) ]);
    $c->status(200, [ $rs->all ]);
}

=head2 find_validation

Chainable action that uses the C<legacy_validation_id_or_name> value provided in the stash (usually
via the request URL) to look up a validation, and stashes the query to get to it in
C<validation_rs>.

=cut

sub find_validation($c) {
    my $identifier = $c->stash('legacy_validation_id_or_name');

    my $validation_rs = $c->db_validations->search({
        (is_uuid($identifier) ? 'id' : 'name') => $identifier,
    });

    if (not $validation_rs->exists) {
        $c->log->debug('Could not find validation '.$identifier);
        return $c->status(404);
    }

    $c->stash('validation_rs', $validation_rs);
    return 1;
}

=head2 get

Get the Validation specified by uuid or name.

Response uses the LegacyValidation json schema.

=cut

sub get ($c) {
    my $validation = $c->stash('validation_rs')->single;
    $c->log->debug('Found validation '.$validation->id);
    return $c->status(200, $validation);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
