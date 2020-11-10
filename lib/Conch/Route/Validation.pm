package Conch::Route::Validation;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::Validation

=head1 METHODS

=head2 routes

Sets up the routes for /validation.

All routes are B<deprecated> and will be removed in Conch API v3.1.

=cut

sub routes {
    my $class = shift;
    my $v = shift;  # secured, under /validation

    $v->to(controller => 'validation', deprecated => 'v3.1');

    # GET /validation
    $v->get('/')->to('#get_all');

    {
        my $with_validation = $v->under('/:legacy_validation_id_or_name')->to('#find_validation');

        # GET /validation/:legacy_validation_id_or_name
        $with_validation->get('/')->to('#get');
    }
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /validation>

=over 4

=item * Controller/Action: L<Conch::Controller::Validation/get_all>

=item * Response: F<response.yaml#/definitions/LegacyValidations>

=back

=head2 C<GET /validation/:legacy_validation_id_or_name>

=over 4

=item * Controller/Action: L<Conch::Controller::Validation/get>

=item * Response: F<response.yaml#/definitions/LegacyValidation>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
