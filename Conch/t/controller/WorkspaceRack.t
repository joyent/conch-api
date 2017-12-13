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


my @fake_store;
$t->app->helper(workspace_rack => sub {
    qobj(
      list => qmeth { \@fake_store },
      add_to_workspace => qmeth {
        my (undef, undef, $id) = @_;
        #conflict if 9
        return Attempt::fail('conflict')
          if $id == 9;
        push @fake_store, $id;
        return Attempt::success;
      },
      remove_from_workspace => qmeth {
        my (undef, undef, $id) = @_;
        #conflict if 8
        return Attempt::fail('conflict')
          if $id == 8;
        @fake_store = grep {!/^$id$/} @fake_store;
        return Attempt::success;
      },
      lookup => qmeth {
        my (undef, undef, $id) = @_;
        my @found = grep {/$id/} @fake_store;
        return Attempt::fail() unless $found[0];
        return Attempt::success();
      },
      rack_layout => qmeth { shift; shift; },
    )
  });


subtest 'Add rack to workspace' => sub {
  $t->post_ok('/workspace/1/rack')->status_is(400, 'Requires request body')
    ->json_like('/error', qr//);
  $t->post_ok('/workspace/1/rack', json => {id => 1} )->status_is(303)
    ->header_like(Location => qr!/workspace/1/rack/1!);
  $t->post_ok('/workspace/1/rack', json => {id => 9} )->status_is(409)
    ->json_like('/error', qr/conflict/);
};
$t->get_ok('/workspace/1/rack')->status_is(200);

subtest 'Get rack in workspace' => sub {
  $t->get_ok('/workspace/1/rack/1')->status_is(200);
  $t->get_ok('/workspace/1/rack/2')->status_is(404)
    ->json_like('/error', qr/not found/);
};

subtest 'Remove rack from workspace' => sub {
  $t->delete_ok('/workspace/1/rack/1')->status_is(204);
  $t->get_ok('/workspace/1/rack/1')->status_is(404)
    ->json_like('/error', qr/not found/);

  $t->post_ok('/workspace/1/rack', json => {id => 8} )->status_is(303);
  $t->delete_ok('/workspace/1/rack/8')->status_is(409)
    ->json_like('/error', qr/conflict/);
};

done_testing();

