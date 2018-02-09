=pod

=head1 NAME

Conch::Route

=head1 DESCRIPTION

Setup all the routes for the Conch Mojo app

=head1 METHODS

=cut

package Conch::Route;
use Mojo::Base -strict;

use Conch::Route::Workspace;
use Conch::Route::User;
use Conch::Route::Device;
use Conch::Route::Relay;
use Conch::Route::HardwareProduct;

use Exporter 'import';
our @EXPORT = qw(
	all_routes
);


=head2 all_routes

Set up the full route structure

=cut

sub all_routes {
	my $r = shift;

	my $unsecured = $r->under(
		sub {
			return 1;
		}
	);

	$unsecured->get( '/', sub { shift->reply->static('../public/index.html') } );

	$unsecured->get(
		'/ping',
		sub {
			shift->status( 200, { status => 'ok' } );
		}
	);

	my $git_rev = `git describe`;
	chomp($git_rev);
	$unsecured->get('/version' => sub { 
		shift->status(200, { version => $git_rev });
	});

	$unsecured->post('/login')->to('login#session_login');
	$unsecured->post('/logout')->to('login#session_logout');
	$unsecured->post('/reset_password')->to('login#reset_password');

	my $secured = $r->under->to('login#authenticate');
	$secured->get( '/login', sub { shift->status(204) } );
	$secured->get( '/me',    sub { shift->status(204) } );

	$secured->post(
		'/feedback',
		sub {
			my $c = shift;
			$c->app->log->warn( $c->req->body );
		}
	);

	workspace_routes($secured);
	device_routes($secured);
	relay_routes($secured);
	user_routes( $secured->under('/user/me') );
	hardware_product_routes($secured);
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

