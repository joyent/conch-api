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
    $root,    # this is the base routing object
) {

    # provides a route to chain to that first checks the user is a system admin.
    $root->add_shortcut(require_system_admin => sub {
        my ($r, $path) = @_;
        $r->any(sub {
            my $c = shift;
            return $c->status(401)
                unless $c->stash('user') and $c->stash('user_id');

            return $c->status(403, { error => 'Must be system admin' })
                unless $c->is_system_admin;

            return 1;
        })->under;
    });

    # allow routes to be specified as, e.g. ->get('/<device_id:uuid>')->to(...)
    $root->add_type(uuid => Conch::UUID::UUID_FORMAT);


    # GET /doc
    $root->get( '/doc',
        sub { shift->reply->static('public/doc/index.html') } );

    # GET /ping
    $root->get(
        '/ping',
        sub { shift->status( 200, { status => 'ok' } ) },
    );

    # GET /version
    $root->get(
        '/version' => sub {
            my $c = shift;
            $c->status( 200, { version => $c->version_tag } );
        }
    );

    # POST /login
    $root->post('/login')->to('login#session_login');

    # POST /logout
    $root->post('/logout')->to('login#session_logout');

    # POST /reset_password
    $root->post('/reset_password')->to('login#reset_password');

    # GET /schema/:input_or_response/:schema_name
    $root->get( '/schema/:request_or_response/:name' =>
        [ request_or_response => [qw(request response)] ] )->to('schema#get');

    # GET /workspace/:workspace/device-totals
    $root->get('/workspace/:workspace/device-totals')->to('workspace_device#device_totals');

    # all routes after this point require authentication

    my $secured = $root->under('/')->to('login#authenticate');

    $secured->get( '/login', sub { shift->status(204) } );
    $secured->get( '/me',    sub { shift->status(204) } );
    $secured->post('/refresh_token')->to('login#refresh_token');

    Conch::Route::Workspace->routes($secured->any('/workspace'));
    Conch::Route::Device->routes($secured->any('/device'));
    Conch::Route::DeviceReport->routes($secured->any('/device_report'));
    Conch::Route::Relay->routes($secured->any('/relay'));
    Conch::Route::User->routes($secured->any('/user'));
    Conch::Route::HardwareProduct->routes($secured->any('/hardware_product'));
    Conch::Route::Validation->routes($secured);

    Conch::Route::Datacenter->routes($secured);

    Conch::Route::HardwareVendor->routes($secured->any('/hardware_vendor'));
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
