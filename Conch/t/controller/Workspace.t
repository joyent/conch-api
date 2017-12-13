use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;

use Data::Printer;
use Mojo::Conch::Route::Workspace 'workspace_routes';

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

my ($mock_workspace_model, $mock_control) = qobjc(
    get_user_workspaces => qmeth { [] },
    get_user_workspace => qmeth {
      my (undef, undef, $ws_id) = @_;
      if ($ws_id == 1) {
        return Attempt::success(qobj( id => $ws_id, as_v2_json => qmeth {}));
      } else {
        return Attempt::fail();
      }
    },
    get_user_sub_workspace => qmeth { shift->get_user_workspace(@_) },
    create_sub_workspace => qmeth { shift->get_user_workspace(@_); }
  );

$t->app->helper(workspace => sub { $mock_workspace_model });


$t->get_ok('/workspace')->status_is(200);
is($mock_control->metrics->{get_user_workspaces}, 1, 'get_user_workspaces called');

$t->get_ok('/workspace/1')->status_is(200);
$t->get_ok('/workspace/2')->status_is(404);

$t->get_ok('/workspace/1/child')->status_is(200);
$t->get_ok('/workspace/2/child')->status_is(404);

$t->post_ok('/workspace/2/child')->status_is(404);
$t->post_ok('/workspace/1/child')->status_is(401, 'No body is bad request');
$t->post_ok('/workspace/1/child', json => { name => 'test sub-workspace' } )
  ->status_is(201, 'Create sub-workspace');
is($mock_control->metrics->{create_sub_workspace}, 1, 'create_sub_workspace called');


done_testing();
