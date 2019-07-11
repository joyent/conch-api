package Conch::Route;

use Mojo::Base -strict, -signatures;

use Conch::UUID;
use Conch::Route::Workspace;
use Conch::Route::Device;
use Conch::Route::DeviceReport;
use Conch::Route::Relay;
use Conch::Route::User;
use Conch::Route::HardwareProduct;
use Conch::Route::Validation;
use Conch::Route::Datacenter;
use Conch::Route::DatacenterRoom;
use Conch::Route::RackRole;
use Conch::Route::Rack;
use Conch::Route::RackLayout;
use Conch::Route::HardwareVendor;

=pod

=head1 NAME

Conch::Route

=head1 DESCRIPTION

Set up all the routes for the Conch Mojo application.

=head1 METHODS

=head2 all_routes

Set up the full route structure

=cut

sub all_routes (
    $class,
    $root,  # this is the base routing object
    $app,   # the Conch app
) {

    # provides a route to chain to that first checks the user is a system admin.
    $root->add_shortcut(require_system_admin => sub ($r) {
        $r->any(sub ($c) {
            return $c->status(401)
                if not $c->stash('user') or not $c->stash('user_id');

            if (not $c->is_system_admin) {
                $c->log->debug('User must be system admin');
                return $c->status(403);
            }

            return 1;
        })->under;
    });

    # allow routes to be specified as, e.g. ->get('/<device_id:uuid>')->to(...)
    $root->add_type(uuid => Conch::UUID::UUID_FORMAT);


    # GET /ping
    $root->get('/ping', sub ($c) { $c->status(200, { status => 'ok' }) });

    # GET /version
    $root->get('/version', sub ($c) { $c->status(200, { version => $c->version_tag }) });

    # POST /login
    $root->post('/login')->to('login#session_login');

    # POST /logout
    $root->post('/logout')->to('login#session_logout');

    # GET /schema/query_params/:schema_name
    # GET /schema/request/:schema_name
    # GET /schema/response/:schema_name
    $root->get('/schema/:schema_type/:name',
        [ schema_type => [qw(query_params request response)] ])->to('schema#get');

    # GET /workspace/:workspace/device-totals
    $root->get('/workspace/:workspace/device-totals')->to('workspace_device#device_totals');

    # all routes after this point require authentication

    my $secured = $root->under('/')->to('login#authenticate');

    $secured->get('/me', sub ($c) { $c->status(204) });
    $secured->post('/refresh_token')->to('login#refresh_token');

    Conch::Route::Workspace->routes($secured->any('/workspace'));
    Conch::Route::Device->routes($secured->any('/device'), $app);
    Conch::Route::DeviceReport->routes($secured->any('/device_report'));
    Conch::Route::Relay->routes($secured->any('/relay'));
    Conch::Route::User->routes($secured->any('/user'));
    Conch::Route::HardwareProduct->routes($secured->any('/hardware_product'));
    Conch::Route::Validation->routes($secured);
    Conch::Route::Datacenter->routes($secured->any('/dc'));
    Conch::Route::DatacenterRoom->routes($secured->any('/room'));
    Conch::Route::RackRole->routes($secured->any('/rack_role'));
    Conch::Route::Rack->routes($secured->any('/rack'));
    Conch::Route::RackLayout->routes($secured->any('/layout'));
    Conch::Route::HardwareVendor->routes($secured->any('/hardware_vendor'));

    $root->any('/*all', sub ($c) {
        $c->log->error('no endpoint found for: '.$c->req->method.' '.$c->req->url->path);
        $c->status(404);
    })->name('catchall');
}

1;
__END__

=pod

Unless otherwise specified all routes require authentication.

Full access is granted to system admin users, regardless of workspace or other role entries.

Successful (http 2xx code) response structures are as described for each endpoint.

Error responses will use:

=over

=item * failure to validate query parameters: http 400, response.yaml#/QueryParamsValidationError

=item * failure to validate request body payload: http 400, response.yaml#/RequestValidationError

=item * all other errors, unless specified: http 4xx, response.yaml/#Error

=back

=head3 C<GET /ping>

=over 4

=item * Does not require authentication.

=item * Response: response.yaml#/Ping

=back

=head3 C<GET /version>

=over 4

=item * Does not require authentication.

=item * Response: response.yaml#/Version

=back

=head3 C<POST /login>

=over 4

=item * Request: request.yaml#/Login

=item * Response: response.yaml#/Login

=back

=head3 C<POST /logout>

=over 4

=item * Does not require authentication.

=item * Response: C<204 NO CONTENT>

=back

=head3 C<GET /schema/query_params/:schema_name>

=head3 C<GET /schema/request/:schema_name>

=head3 C<GET /schema/response/:schema_name>

Returns the schema specified by type and name.

=over 4

=item * Does not require authentication.

=item * Response: JSON-Schema (L<http://json-schema.org/draft-07/schema>)

=back

=head3 C<GET /workspace/:workspace/device-totals>

=head3 C<GET /workspace/:workspace/device-totals.circ>

=over 4

=item * Does not require authentication.

=item * Response: response.yaml#/DeviceTotals

=item * Response (Circonus): response.yaml#/DeviceTotalsCirconus

=back

=head3 C<POST /refresh_token>

=over 4

=item * Request: request.yaml#/Null

=item * Response: response.yaml#/Login

=back

=head3 C<* /dc>, C<* /room>, C<* /rack_role>, C<* /rack>, C<* /layout>

See L<Conch::Route::Datacenter/routes>

=head3 C<* /device>

See L<Conch::Route::Device/routes>

=head3 C<* /device_report>

See L<Conch::Route::DeviceReport/routes>

=head3 C<* /hardware_product>

See L<Conch::Route::HardwareProduct/routes>

=head3 C<* /hardware_vendor>

See L<Conch::Route::HardwareVendor/routes>

=head3 C<* /relay>

See L<Conch::Route::Relay/routes>

=head3 C<* /user>

See L<Conch::Route::User/routes>

=head3 C<* /validation>, C<* /validation_plan>, C<* /validation_state>

See L<Conch:Route::Validation/routes>

=head3 C<* /workspace>

See L<Conch::Route::Workspace/routes>

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
