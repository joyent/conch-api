package Conch::Route::Schema;

use Mojo::Base -strict, -signatures;

=pod

=head1 NAME

Conch::Route::Schema

=head1 METHODS

=head2 routes

Sets up the routes for /schema.

=cut

sub routes {
    my $class = shift;
    my $schema = shift;    # NOT secured, under /schema

    $schema->to({ controller => 'schema' });

    # GET /schema/query_params/:schema_name
    # GET /schema/request/:schema_name
    # GET /schema/response/:schema_name
    $schema->get('/:schema_type/:name',
        [ schema_type => [qw(query_params request response)] ])->to('#get');
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

=head2 C<GET /schema/query_params/:schema_name>

=head2 C<GET /schema/request/:schema_name>

=head2 C<GET /schema/response/:schema_name>

Returns the schema specified by type and name.

=over 4

=item * Does not require authentication.

=item * Response: a JSON Schema (L<http://json-schema.org/draft-07/schema#>)

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
