use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;

use Data::Printer;
use Conch::Route::User 'user_routes';

my $t = Test::Mojo->new(Mojolicious->new);

my $routes = $t->app->routes;
push @{$routes->namespaces}, 'Conch::Controller';
user_routes($routes);
$t->app->helper(status => sub {
    my $self = shift;
    $self->res->code(shift);
    my $payload = shift;
    return $payload ?  $self->render(json => $payload) : $self->finish;
  });

my $settings_store = {};
$t->app->helper(user_settings => sub {
    qobj(
      set_settings => qmeth {
        my (undef, undef, $new_settings) = @_;
        $settings_store = { %$settings_store, %$new_settings };
      },
      get_settings => qmeth {
        return $settings_store;
      },
      # returns 1 if deleted, 0 otherwise
      delete_user_setting => qmeth {
        if (defined $settings_store->{$_[2]}) {
          delete $settings_store->{$_[2]};
          return 1;
        } else {
          return 0;
        }
      }
    );
  });

$t->get_ok('/settings')->status_is(200);
$t->get_ok('/settings/foo')->status_is(404);

$t->post_ok('/settings' )->status_is(400, 'Requires body');
$t->post_ok('/settings', json => { foo => 'bar' } )->status_is(200, 'Requires body');
$t->get_ok('/settings')->status_is(200)
  ->json_is('/foo', 'bar', 'Setting was stored');

$t->get_ok('/settings/foo')->status_is(200)
  ->content_is('"bar"', 'Setting was stored');

$t->post_ok('/settings/fizzle', json => { no_match => 'gibbet' })
  ->status_is(400, 'Fail if parameter and key do not match');
$t->post_ok('/settings/fizzle', json => { fizzle => 'gibbet' })
  ->status_is(200);
$t->get_ok('/settings/fizzle')
  ->status_is(200)
  ->content_is('"gibbet"');

$t->delete_ok('/settings/fizzle')
  ->status_is(204)
  ->content_is('');
$t->get_ok('/settings/fizzle')
  ->status_is(404);
$t->delete_ok('/settings/fizzle')
  ->status_is(404)
  ->json_like('/error', qr/fizzle/);

done_testing();
