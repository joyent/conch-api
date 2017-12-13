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

my ($mock_workspace_model, $workspace_model_control) = qobjc(
  get_user_workspaces => qmeth { [] },
  get_user_workspace  => qmeth {
      Attempt::success( qobj(
          id => 1,
          name => 'GLOBAL'
        )
      );
    }
);

$t->app->helper( workspace => sub { $mock_workspace_model } );

$t->app->helper(workspace_room => sub {
    qobj(
      list => qmeth { [] },
      replace_workspace_rooms => qmeth {
        my (undef, undef, $room_ids) = @_;
        if (grep { $_ == 10 } @$room_ids) {
          return Attempt::fail('conflict');
        } else {
          return Attempt::success($room_ids);
        }
      },
    )
  });

$t->get_ok('/workspace/1/room')->status_is(200);

$t->put_ok('/workspace/1/room')->status_is(400, 'Requires body')
  ->json_like('/error' => qr/datacenter room IDs required/);

$t->put_ok('/workspace/1/room', json => [1, 2, 3] )->status_is(400, 'Cannot modify GLOBAL')
  ->json_like('/error' => qr/Cannot modify GLOBAL/);

$workspace_model_control->set_methods(
  get_user_workspace => qmeth {
    Attempt::success( qobj(
        id => 1,
        name => 'Not global',
        role => 'Read-only'
      ));
  });

$t->put_ok('/workspace/1/room', json => [1, 2, 3] )->status_is(401, 'Must be Administrator')
  ->json_like('/error' => qr/Only workspace administrators/);

$workspace_model_control->set_methods(
  get_user_workspace => qmeth {
    Attempt::success( qobj(
        id => 1,
        name => 'Not global',
        role => 'Administrator'
      ));
  });

$t->put_ok('/workspace/1/room', json => [1, 2, 3] )->status_is(200, 'Replaced datacenter rooms')
  ->json_is([1, 2, 3]);

# ID 10 is designated to cause conflict in mock
$t->put_ok('/workspace/1/room', json => [10, 2, 3] )->status_is(409, 'Conflict occurs with replacement')
  ->json_like('/error', qr/conflict/);

done_testing();

