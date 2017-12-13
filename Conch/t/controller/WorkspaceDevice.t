use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;

use Data::Printer;
use Mojo::Conch::Route::Workspace 'workspace_routes';
use aliased 'Mojo::Conch::Class::Device';

my $t = Test::Mojo->new(Mojolicious->new);

my $routes = $t->app->routes;
push @{$routes->namespaces}, 'Mojo::Conch::Controller';
workspace_routes($routes);

$t->app->helper(status => sub {
    my $self = shift;
    $self->res->code(shift);
    my $payload = shift;
    return $payload ?  $self->render(json => $payload) : $self->finish;
  });

my ($mock_workspace_model, $workspace_model_control) = qobjc(
  get_user_workspaces => qmeth { [] },
  get_user_workspace  => qmeth {
    }
);

$t->app->helper( workspace => sub {
    qobj(
      get_user_workspace => qmeth {
        Attempt::success( qobj(
            id => 1,
            name => 'GLOBAL'
          )
        );
      }
    )
  });

$t->app->helper(workspace_device => sub {
    qobj(
      list => qmeth {
        my $last_seen = $_[2];
        if (defined $last_seen) {
            return [ Device->new(id => '10', graduated => undef, health => 'PASS') ];
        } else {
          [
            Device->new(id => '10', graduated => undef, health => 'PASS'),
            Device->new(id => '20', graduated => '2018-01-01', health => 'PASS'),
            Device->new(id => '30', graduated => '2018-01-01', health => 'FAIL')
          ]
        }
      },
    )
  });

$t->get_ok('/workspace/1/device')->status_is(200)->json_is('/0/id', '10');

$t->get_ok('/workspace/1/device?graduated=f')->status_is(200)->json_is('/0/id', '10');
$t->get_ok('/workspace/1/device?graduated=F')->status_is(200)->json_is('/0/id', '10');
$t->get_ok('/workspace/1/device?graduated=t')->status_is(200)->json_is('/0/id', '20');;
$t->get_ok('/workspace/1/device?graduated=T')->status_is(200)->json_is('/0/id', '20');;

$t->get_ok('/workspace/1/device?health=fail')->status_is(200)->json_is('/0/id', '30');;
$t->get_ok('/workspace/1/device?health=FAIL')->status_is(200)->json_is('/0/id', '30');;
$t->get_ok('/workspace/1/device?health=pass')->status_is(200)->json_is('/0/id', '10');;
$t->get_ok('/workspace/1/device?health=PASS')->status_is(200)->json_is('/0/id', '10');;

$t->get_ok('/workspace/1/device?health=pass&graduated=t')->status_is(200)->json_is('/0/id', '20');;
$t->get_ok('/workspace/1/device?health=pass&grauadted=f')->status_is(200)->json_is('/0/id', '10');;

$t->get_ok('/workspace/1/device?ids_only=1')->status_is(200)->content_is('["10","20","30"]');
$t->get_ok('/workspace/1/device?ids_only=1&health=pass')->status_is(200)->content_is('["10","20"]');

$t->get_ok('/workspace/1/device?active=t')->status_is(200)->json_is('/0/id', '10');;
$t->get_ok('/workspace/1/device?active=t&graduated=t')->status_is(200)->content_is('[]');;

done_testing();

