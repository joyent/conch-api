use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;
use Data::UUID;

use Data::Printer;
use Conch::Route::HardwareProduct 'hardware_product_routes';
use aliased 'Conch::Class::HardwareProduct';
use aliased 'Conch::Class::HardwareProductProfile';
use aliased 'Conch::Class::ZpoolProfile';

my $uuid = Data::UUID->new;

my $t = Test::Mojo->new(Mojolicious->new);

my $routes = $t->app->routes;
push @{$routes->namespaces}, 'Conch::Controller';
hardware_product_routes($routes);

$t->app->helper(status => sub {
    my $self = shift;
    $self->res->code(shift);
    my $payload = shift;
    return $payload ?  $self->render(json => $payload) : $self->finish;
  });


my $fake_hw_product =
  HardwareProduct->new(
    id => 10,
    profile => HardwareProductProfile->new(
      zpool => ZpoolProfile->new(
        name => 'test zpool'
      )
    ));
my $mock_hardware_product_model = qobj(
  list => qmeth {
    [ $fake_hw_product ];
  },
  lookup => qmeth {
    if ($_[1] == 10) {
      return Attempt::success( $fake_hw_product);
    } else {
      return Attempt::fail;
    }
  }
);

$t->app->helper(hardware_product => sub { $mock_hardware_product_model });

$t->get_ok('/hardware_product')->status_is(200)
  ->json_is('/0/id', 10)
  ->json_is('/0/profile/zpool/name', 'test zpool');

$t->get_ok('/hardware_product/10')->status_is(200)
  ->json_is('/id', 10)
  ->json_is('/profile/zpool/name', 'test zpool');

$t->get_ok('/hardware_product/20')->status_is(404);

done_testing();

