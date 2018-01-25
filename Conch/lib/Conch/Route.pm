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

sub all_routes {
	my $r = shift;

	my $unsecured = $r->under(
		sub {
			return 1;
		}
	);

	$unsecured->get( '/', sub { shift->reply->static('../public/index.html') } );

	$unsecured->get( '/js/app.js',
		sub { shift->reply->static('../public/js/app.js') } );

	$unsecured->get(
		'/ping',
		sub {
			shift->status( 200, { status => 'ok' } );
		}
	);

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
