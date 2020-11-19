package Conch::Route;

use Mojo::Base -strict, -signatures;
use List::Util qw(uniqstr any);
use feature 'state';
use feature 'current_sub';

use Conch::UUID;
use Conch::Route::JSONSchema;
use Conch::Route::Device;
use Conch::Route::DeviceReport;
use Conch::Route::Relay;
use Conch::Route::User;
use Conch::Route::HardwareProduct;
use Conch::Route::Datacenter;
use Conch::Route::DatacenterRoom;
use Conch::Route::RackRole;
use Conch::Route::Rack;
use Conch::Route::RackLayout;
use Conch::Route::HardwareVendor;
use Conch::Route::Organization;
use Conch::Route::Build;
use Conch::Route::ValidationPlan;
use Conch::Route::ValidationState;

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

These are available on all routes. See L<Mojolicious::Guides::Routing/Shortcuts>.

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

=head2 root

Returns the root node.

=cut

    $root->add_shortcut(root => sub ($r) {
        my $root = $r;
        $root = $root->parent while $root->parent;
        $root;
    });


    # allow routes to be specified as, e.g. ->get('/<device_id:uuid>')->to(...)
    $root->add_type(uuid => Conch::UUID::UUID_FORMAT);

    # one component of a JSON Pointer, e.g. for specifying JSON Schemas
    $root->add_type(json_pointer_token => qr{[^/.~]+});

    # GET /ping
    $root->get('/ping', sub ($c) { $c->status(200, { status => 'ok' }) });

    # GET /version
    $root->get('/version', sub ($c) {
        $c->res->headers->last_modified(Mojo::Date->new($c->startup_time->epoch));
        $c->status(200, { version => $c->version_tag })
    });

    # POST /login
    $root->post('/login')->to('login#login');

    # * /json_schema/...
    Conch::Route::JSONSchema->unsecured_routes($root->any('/json_schema'));

    # all routes after this point require authentication

    my $secured = $root->under('/')->to('login#authenticate');

    # POST /logout
    $secured->post('/logout')->to('login#logout');

    # GET /me
    $secured->get('/me', sub ($c) { $c->status(204) });

    # POST /refresh_token
    $secured->post('/refresh_token')->to('login#refresh_token');

    Conch::Route::Device->routes($secured->any('/device'), $app);
    Conch::Route::DeviceReport->routes($secured->any('/device_report'));
    Conch::Route::Relay->routes($secured->any('/relay'));
    Conch::Route::User->routes($secured->any('/user'));
    Conch::Route::HardwareProduct->routes($secured->any('/hardware_product'));
    Conch::Route::Datacenter->routes($secured->any('/dc'));
    Conch::Route::DatacenterRoom->routes($secured->any('/room'));
    Conch::Route::RackRole->routes($secured->any('/rack_role'));
    Conch::Route::Rack->routes($secured->any('/rack'));
    Conch::Route::RackLayout->routes($secured->any('/layout'));
    Conch::Route::HardwareVendor->routes($secured->any('/hardware_vendor'));
    Conch::Route::Organization->routes($secured->any('/organization'));
    Conch::Route::Build->routes($secured->any('/build'));
    Conch::Route::ValidationPlan->routes($secured->any('/validation_plan'));
    Conch::Route::ValidationState->routes($secured->any('/validation_state'));

    # find all the top level path components: these are the only paths that we will send rollbar alerts for
    state sub find_paths ($route) {
        if (my $pattern = $route->pattern->unparsed) {
            return ($pattern =~ m{^/([^/]+)})[0];
        }

        # this is an under route with no path -- keep looking
        return map __SUB__->($_), $route->children->@*;
    }

    my @top_level_paths = (uniqstr (map find_paths($_), $root->children->@*),
        qw(validation workspace));

    $root->any('/*all', sub ($c) {
        $c->log->warn('no endpoint found for: '.$c->req->method.' '.$c->req->url->path);

        if (any { $c->req->url->path =~ m{^/$_\b} } @top_level_paths) {
            $c->stash('top_level_path_match', 1);
            $c->on(finish => sub ($c) {
                $c->send_message_to_rollbar('warning', 'no endpoint found for: '.$c->req->method.' '.$c->req->url->path);
            }) if $c->feature('rollbar');
        }

        $c->status(404, { error => 'Route Not Found' });
    })->name('catchall');
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

Unless otherwise specified, all routes require authentication.

Full access is granted to system admin users, regardless of build or other role entries.

Successful (HTTP 2xx code) response structures are as described for each endpoint.

Error responses will use:

=over

=item * failure to validate query parameters: HTTP 400, F<response.yaml#/$defs/QueryParamsValidationError>

=item * failure to validate request body payload: HTTP 400, F<response.yaml#/$defs/RequestValidationError>

=item * all other errors, unless specified: HTTP 4xx, F<response.yaml#/$defs/Error>

=back

=head2 C<GET /ping>

=over 4

=item * Does not require authentication.

=item * Response: F<response.yaml#/$defs/Ping>

=back

=head2 C<GET /version>

=over 4

=item * Does not require authentication.

=item * Response: F<response.yaml#/$defs/Version>

=back

=head2 C<POST /login>

=over 4

=item * Controller/Action: L<Conch::Controller::Login/login>

=item * Request: F<request.yaml#/$defs/Login>

=item * Response: F<response.yaml#/$defs/LoginToken>

=back

=head2 C<POST /logout>

=over 4

=item * Controller/Action: L<Conch::Controller::Login/logout>

=item * Request: F<request.yaml#/$defs/Null>

=item * Response: C<204 No Content>

=back

=head2 C<POST /refresh_token>

=over 4

=item * Controller/Action: L<Conch::Controller::Login/refresh_token>

=item * Request: F<request.yaml#/$defs/Null>

=item * Response: F<response.yaml#/$defs/LoginToken>

=back

=head2 C<GET /me>

=over 4

=item * Response: C<204 No Content>

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

=head2 C<* /json_schema>

See L<Conch::Route::JSONSchema/unsecured_routes>

=head2 C<* /user>

See L<Conch::Route::User/routes>

=head2 C<* /validation_plan>

See L<Conch::Route::ValidationPlan/routes>

=head2 C<* /validation_state>

See L<Conch::Route::ValidationState/routes>

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
