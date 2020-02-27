package Conch::Route;

use Mojo::Base -strict, -signatures;
use List::Util qw(uniq any);
use feature 'state';
use feature 'current_sub';

use Conch::UUID;
use Conch::Route::Schema;
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
use Conch::Route::Organization;
use Conch::Route::Build;

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

=head1 SHORTCUTS

These are available on the root router. See L<Mojolicious::Guides::Routing/Shortcuts>.

=head2 require_system_admin

Chainable route that aborts with HTTP 403 if the user is not a system admin.

=cut

    $root->add_shortcut(require_system_admin => sub ($r) {
        $r->under('/', sub ($c) {
            if (not $c->stash('user') or not $c->stash('user_id')) {
                $c->log->fatal('tried to check for system admin on an unauthenticated endpoint?');
                return $c->status(401);
            }

            if (not $c->is_system_admin) {
                $c->log->debug('User must be system admin');
                return $c->status(403);
            }

            return 1;
        });
    });

=head2 find_user_from_payload

Chainable route that looks up the user by C<user_id> or C<email> in the JSON payload,
aborting with HTTP 410 or HTTP 404 if not found.

=cut

    # provides a route to chain to that looks up the user provided in the payload
    $root->add_shortcut(find_user_from_payload => sub ($r) {
        $r->under('/', sub ($c) {
            my $input = $c->validate_request('UserIdOrEmail');
            return if not $input;

            $c->stash('target_user_id_or_email', $input->{user_id} // $input->{email});
            return 1;
        })
        ->under('/')->to('user#find_user');
    });

    # allow routes to be specified as, e.g. ->get('/<device_id:uuid>')->to(...)
    $root->add_type(uuid => Conch::UUID::UUID_FORMAT);


    # GET /ping
    $root->get('/ping', sub ($c) { $c->status(200, { status => 'ok' }) });

    # GET /version
    $root->get('/version', sub ($c) {
        $c->res->headers->last_modified(Mojo::Date->new($c->startup_time->epoch));
        $c->status(200, { version => $c->version_tag })
    });

    # POST /login
    $root->post('/login')->to('login#login');

    Conch::Route::Schema->routes($root->any('/schema'));

    # GET /workspace/:workspace/device-totals
    $root->get('/workspace/:workspace/device-totals')->to('workspace_device#device_totals', deprecated => 'v3.1');

    # all routes after this point require authentication

    my $secured = $root->under('/')->to('login#authenticate');

    # POST /logout
    $secured->post('/logout')->to('login#logout');

    # GET /me
    $secured->get('/me', sub ($c) { $c->status(204) });

    # POST /refresh_token
    $secured->post('/refresh_token')->to('login#refresh_token');

    Conch::Route::Workspace->routes($secured->any('/workspace')->to(deprecated => 'v3.1'));
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
    Conch::Route::Organization->routes($secured->any('/organization'));
    Conch::Route::Build->routes($secured->any('/build'));

    # find all the top level path components: these are the only paths that we will send rollbar alerts for
    state sub find_paths ($route) {
        if (my $pattern = $route->pattern->unparsed) {
            return ($pattern =~ m{^(/[^/]+)})[0];
        }

        # this is an under route with no path -- keep looking
        return map __SUB__->($_), $route->children->@*;
    }

    my @top_level_paths = uniq map find_paths($_), $root->children->@*;

    $root->any('/*all', sub ($c) {
        $c->log->warn('no endpoint found for: '.$c->req->method.' '.$c->req->url->path);

        $c->on(finish => sub ($c) {
            $c->send_message_to_rollbar('warning', 'no endpoint found for: '.$c->req->method.' '.$c->req->url->path);
        })
        if $c->feature('rollbar') and any { $c->req->url->path =~ m{^$_/} } @top_level_paths;

        $c->status(404, { error => 'Route Not Found' });
    })->name('catchall');
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

Unless otherwise specified, all routes require authentication.

Full access is granted to system admin users, regardless of workspace, build or other role
entries.

Successful (HTTP 2xx code) response structures are as described for each endpoint.

Error responses will use:

=over

=item * failure to validate query parameters: HTTP 400, F<response.yaml#/definitions/QueryParamsValidationError>

=item * failure to validate request body payload: HTTP 400, F<response.yaml#/RequestValidationError>

=item * all other errors, unless specified: HTTP 4xx, F<response.yaml#/Error>

=back

=head2 C<GET /ping>

=over 4

=item * Does not require authentication.

=item * Response: F<response.yaml#/definitions/Ping>

=back

=head2 C<GET /version>

=over 4

=item * Does not require authentication.

=item * Response: F<response.yaml#/definitions/Version>

=back

=head2 C<POST /login>

=over 4

=item * Request: F<request.yaml#/definitions/Login>

=item * Response: F<response.yaml#/definitions/LoginToken>

=back

=head2 C<POST /logout>

=over 4

=item * Request: F<request.yaml#/definitions/Null>

=item * Response: C<204 No Content>

=back

=head2 C<GET /workspace/:workspace/device-totals>

=head2 C<GET /workspace/:workspace/device-totals.circ>

=over 4

=item * Does not require authentication.

=item * Response: F<response.yaml#/definitions/DeviceTotals>

=item * Response (Circonus): F<response.yaml#/definitions/DeviceTotalsCirconus>

=back

=head2 C<POST /refresh_token>

=over 4

=item * Request: F<request.yaml#/definitions/Null>

=item * Response: F<response.yaml#/definitions/LoginToken>

=back

=head2 C<* /dc>, C<* /room>, C<* /rack_role>, C<* /rack>, C<* /layout>

See L<Conch::Route::Datacenter/routes>

=head2 C<* /device>

See L<Conch::Route::Device/routes>

=head2 C<* /device_report>

See L<Conch::Route::DeviceReport/routes>

=head2 C<* /hardware_product>

See L<Conch::Route::HardwareProduct/routes>

=head2 C<* /hardware_vendor>

See L<Conch::Route::HardwareVendor/routes>

=head2 C<* /organization>

See L<Conch::Route::Organization/routes>

=head2 C<* /relay>

See L<Conch::Route::Relay/routes>

=head2 C<* /schema>

See L<Conch::Route::Schema/routes>

=head2 C<* /user>

See L<Conch::Route::User/routes>

=head2 C<* /validation>, C<* /validation_plan>, C<* /validation_state>

See L<Conch::Route::Validation/routes>

=head2 C<* /workspace>

See L<Conch::Route::Workspace/routes>

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
