use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;

use Data::Printer;
use Conch::Route::Workspace 'workspace_routes';

my $t = Test::Mojo->new( Mojolicious->new );

my $routes = $t->app->routes;
push @{ $routes->namespaces }, 'Conch::Controller';
workspace_routes($routes);

### <setup>
$t->app->helper(
  status => sub {
    my $self = shift;
    $self->res->code(shift);
    my $payload = shift;
    return $payload ? $self->render( json => $payload ) : $self->finish;
  }
);

my $mock_workspace_model = qobj(
  get_user_workspaces => qmeth { [] },
  get_user_workspace  => qmeth {
    my ( undef, undef, $ws_id ) = @_;
    if ( $ws_id == 1 ) {
      return Attempt::success( qobj( id => $ws_id, as_v1_json => qmeth {} ) );
    }
    else {
      return Attempt::fail();
    }
  }
);

$t->app->helper( workspace => sub { $mock_workspace_model } );

$t->app->helper(
  workspace_user => sub {
    qobj(
      workspace_users => qmeth { [] }
    );
  }
);

$t->app->helper(
  user => sub {
    qobj(
      lookup_by_email => qmeth {
        shift;
        if (shift eq 'foo@bar.com') {
          return Attempt::success(qobj());
        }
        else {
          return Attempt::fail();
        }
      },
      create => qmeth { qobj( email => 'email') }
    );
  }
);

$t->app->helper(
  role => sub {
    qobj(
      lookup_by_name => qmeth {
        shift;
        if (shift eq 'Administrator') {
          return Attempt::success(qobj());
        }
        else {
          return Attempt::fail();
        }
      },
      list => [qobj( name => 'Administrator')]
    );
  }
);

$t->app->helper(random_string => sub { 'random' });

my ($mock_mail, $mock_mail_control) = qobjc();
$t->app->helper( mail => sub { $mock_mail });

### </setup>


$t->get_ok('/workspace/1/user')->status_is(200);
$t->post_ok('/workspace/1/user')->status_is( 400, 'No payload is bad request' );
$t->post_ok( '/workspace/1/user', json => { user => 'foo@bar.com'} )
  ->status_is( 400, 'No role is bad request' );
$t->post_ok( '/workspace/1/user', json => { role => 'Administrator'} )
  ->status_is( 400, 'No user is bad request' );
$t->post_ok( '/workspace/1/user', json => { user => 'foo@bar.com', role => 'Bad Role'} )
  ->status_is( 400, 'Invalid role is bad request' );

is($mock_mail_control->metrics->{send_existing_user_invite}, undef, 'No existing user invite sent');
$t->post_ok( '/workspace/1/user', json => { user => 'foo@bar.com', role => 'Administrator'} )
  ->status_is( 201, 'Existing user invited' );
is($mock_mail_control->metrics->{send_existing_user_invite}, 1, 'Existing user invite sent');

is($mock_mail_control->metrics->{send_new_user_invite}, undef, 'No new user invite sent');
$t->post_ok( '/workspace/1/user', json => { user => 'baz@bar.com', role => 'Administrator'} )
  ->status_is( 201, 'New user invited' );
is($mock_mail_control->metrics->{send_new_user_invite}, 1, 'New user invite sent');

done_testing();
