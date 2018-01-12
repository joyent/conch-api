use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;
use Data::UUID;

use Data::Printer;
use Conch::Route::Device 'device_routes';

my $uuid = Data::UUID->new;

my $t = Test::Mojo->new(Mojolicious->new);

my $routes = $t->app->routes;
push @{$routes->namespaces}, 'Conch::Controller';
device_routes($routes);

$t->app->helper(status => sub {
    my $self = shift;
    $self->res->code(shift);
    my $payload = shift;
    return $payload ?  $self->render(json => $payload) : $self->finish;
  });

my $fake_device = qobj(
  id => qmeth {1},
  latest_triton_reboot => undef,
  triton_uuid => undef,
  as_v1_json => {}
);

my $mock_device_model = qobj(
  lookup_for_user => qmeth {
    shift; shift;
    if (shift == 1) {
      return Attempt::success($fake_device)
    } else {
      return Attempt::fail;
    }
  },
  set_triton_uuid => qmeth {
    shift; shift;
    $fake_device->triton_uuid(shift);
  },
  set_triton_reboot => qmeth {
    $fake_device->latest_triton_reboot('now');
  }
);

$t->app->helper(device => sub { $mock_device_model });
$t->app->helper(device_report => sub {
    qobj(
      latest_device_report => qmeth { Attempt::fail }
    )
  });
$t->app->helper(device_location => sub {
    qobj(
      lookup => qmeth { Attempt::fail }
    )
  });

$t->get_ok('/device/1')->status_is(200);
$t->get_ok('/device/2')->status_is(404)
  ->json_like('/error', qr/not found/);;

$t->post_ok('/device/2/graduate')->status_is(404);

$t->post_ok('/device/1/graduate')->status_is(303)
    ->header_like(Location => qr!/device/1$!);

$t->post_ok('/device/1/triton_setup')->status_is(409)
    ->json_like('/error', qr/must be marked .+ before it can be .+ set up for Triton/);

$t->post_ok('/device/1/triton_reboot')->status_is(303)
    ->header_like(Location => qr!/device/1$!);

$t->post_ok('/device/1/triton_uuid')->status_is(400, 'Request body required');

$t->post_ok('/device/1/triton_uuid', json => { triton_uuid => 'not a UUID' })
  ->status_is(400)
  ->json_like('/error', qr/a UUID/);

$t->post_ok('/device/1/triton_uuid', json => { triton_uuid => $uuid->create_str() })
  ->status_is(303)
  ->header_like(Location => qr!/device/1$!);

$t->post_ok('/device/1/triton_setup')->status_is(303)
  ->header_like(Location => qr!/device/1$!);

$t->post_ok('/device/1/asset_tag')->status_is(400, 'Request body required');

$t->post_ok('/device/1/asset_tag', json => { asset_tag => 'asset tag' } )
  ->status_is(303)
  ->header_like(Location => qr!/device/1$!);


done_testing();
