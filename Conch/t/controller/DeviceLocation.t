use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;
use Data::UUID;

use Data::Printer;
use Mojo::Conch::Route::Device 'device_routes';

my $uuid = Data::UUID->new;

my $t = Test::Mojo->new(Mojolicious->new);

my $routes = $t->app->routes;
push @{$routes->namespaces}, 'Mojo::Conch::Controller';
device_routes($routes);

$t->app->helper(status => sub {
    my $self = shift;
    $self->res->code(shift);
    my $payload = shift;
    return $payload ?  $self->render(json => $payload) : $self->finish;
  });

my $mock_device_model = qobj(
  lookup_for_user => qmeth {
    my $device_id = $_[2];
    Attempt::success(qobj( id => qmeth { $device_id }));
  }
);

my $mock_device_loc_model = qobj(
  lookup => qmeth {
    my $device_id = $_[1];
    if ($device_id == 1) {
      return Attempt::success(qobj());
    } else {
      return Attempt::fail;
    }
  },
  assign => qmeth {
    my $rack_unit = $_[3];
    if ($rack_unit == 4) {
      return Attempt::success;
    } else {
      return Attempt::fail('fail');
    }
  },
  unassign => qmeth {
    my $device_id = $_[1];
    if ($device_id == 1) {
      return 1;
    } else {
      return 0;
    }
  }
);

$t->app->helper(device => sub { $mock_device_model });
$t->app->helper(device_location => sub { $mock_device_loc_model });

$t->get_ok('/device/1/location')->status_is(200);
$t->get_ok('/device/2/location')->status_is(409);

$t->post_ok('/device/1/location')->status_is(400, 'requires body')
  ->json_like('/error', qr/rack_unit/)
  ->json_like('/error', qr/rack_id/);

$t->post_ok('/device/1/location', json => { rack_id => 2, rack_unit => 4 })
  ->status_is(303)
  ->header_like(Location => qr!/device/1/location$!);

$t->post_ok('/device/1/location', json => { rack_id => 2, rack_unit => 5 })
  ->status_is(409)
  ->json_like('/error', qr/fail/);


$t->delete_ok('/device/1/location')
  ->status_is(204);
$t->delete_ok('/device/2/location')
  ->status_is(409)
  ->json_like('/error', qr/not assigned/);

done_testing();
