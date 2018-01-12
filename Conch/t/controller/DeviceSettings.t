use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;

use Data::Printer;
use Conch::Route::Device 'device_routes';

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

my $mock_device_model = qobj(
  lookup_for_user => qmeth {
    my $device_id = $_[2];
    Attempt::success(qobj( id => qmeth { $device_id }));
  }
);
$t->app->helper(device => sub { $mock_device_model });

my $settings_store = {};
$t->app->helper(device_settings => sub {
    qobj(
      set_settings => qmeth {
        my (undef, undef, $new_settings) = @_;
        $settings_store = { %$settings_store, %$new_settings };
      },
      get_settings => qmeth {
        return $settings_store;
      },
      # returns 1 if deleted, 0 otherwise
      delete_device_setting => qmeth {
        if (defined $settings_store->{$_[2]}) {
          delete $settings_store->{$_[2]};
          return 1;
        } else {
          return 0;
        }
      }
    );
  });

$t->get_ok('/device/1/settings')->status_is(200)->content_is('{}');
$t->get_ok('/device/1/settings/foo')->status_is(404);

$t->post_ok('/device/1/settings')->status_is(400, 'Requires body')
  ->json_like('/error', qr/required/);
$t->post_ok('/device/1/settings', json => { foo => 'bar' } )->status_is(200);
$t->get_ok('/device/1/settings')->status_is(200)
  ->json_is('/foo', 'bar', 'Setting was stored');

$t->get_ok('/device/1/settings/foo')->status_is(200)
  ->content_is('"bar"', 'Setting was stored');

$t->post_ok('/device/1/settings/fizzle', json => { no_match => 'gibbet' })
  ->status_is(400, 'Fail if parameter and key do not match');
$t->post_ok('/device/1/settings/fizzle', json => { fizzle => 'gibbet' })
  ->status_is(200);
$t->get_ok('/device/1/settings/fizzle')
  ->status_is(200)
  ->content_is('"gibbet"');

$t->delete_ok('/device/1/settings/fizzle')
  ->status_is(204)
  ->content_is('');
$t->get_ok('/device/1/settings/fizzle')
  ->status_is(404)
  ->json_like('/error', qr/fizzle/);
$t->delete_ok('/device/1/settings/fizzle')
  ->status_is(404)
  ->json_like('/error', qr/fizzle/);

done_testing();
