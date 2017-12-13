use Mojo::Base -strict;
use Mojolicious;
use Test::More;
use Test::Mojo;
use Mock::Quick;
use Attempt;

use Data::Printer;

my $t = Test::Mojo->new('Mojo::Conch');

my $mock_authenticate = sub {
  qobj(
    authenticate => qmeth {
      shift;
      my ($user, $pass) = @_;
      return ($user eq 'bar' && $pass eq 'hunter2')
        ? Attempt::success(qobj( id => 'userid'))
        : Attempt::fail
    },
    lookup => qmeth { Attempt::success },
    lookup_by_email => qmeth {
      shift; my $email = shift;
      return ($email eq 'foo@bar.com')
        ?  Attempt::success(qobj(id => '1', email => 'foo@bar.com'))
        :  Attempt::fail
    }
  );
};

$t->app->helper(user => $mock_authenticate);
$t->app->helper(mail  => sub { qobj( send_password_reset_email => sub { p $t; }) });

$t->post_ok('/login') ->status_is(400, "Bad request without required body");

$t->post_ok('/login' => json => {user => 'bar', password => 'bad'})
  ->status_is(401, "Unauthenticated without correct password" );

$t->app->helper(user => $mock_authenticate);

$t->post_ok('/login' => json => {user => 'bar', password => 'hunter2'})
  ->status_is(200, "Successful authentication")
  ->header_like('Set-Cookie' => qr/^conch\=/);

$t->get_ok('/login')->status_is(204, "User is logged in");
  my $auth_cookie = $t->tx->res->cookies->[0];

subtest "test logout" => sub {
  $t->post_ok('/logout')->status_is(204);
  $t->get_ok('/login')->status_is(401);
};

subtest "verify cookie works" => sub {
  $t->get_ok('/login' => {Cookie => $auth_cookie->to_string} )
    ->status_is(204);
};

subtest "Basic auth can authenticate" => sub {
  $t->reset_session;
  $t->get_ok('/login' => { Authorization => 'Basic YmFyOmh1bnRlcjI=' } )
    ->status_is(204);

  $t->app->helper(user => $mock_authenticate);

  $t->get_ok('/login' => { Authorization => 'Basic Az9vOmJhcg==' } )
    ->status_is(401);
};

# I couldn't come up with an effective way to test whether the
# password_reset_email function was invoked. It's invoked asyncronously if the
# email address is associated with a user. I tried using a spy variable changed
# by the invoked function and Mojo::IOLoop to run the test after the invoked
# function without any success. `sleep` won't work because it's single-threaded.
# Maybe someone cleverer than me can figure it out.
# -- lseppala
subtest "Password reset" => sub {
  $t->reset_session;
  $t->post_ok('/reset_password')->status_is(400);
  $t->post_ok('/reset_password', json => { email => 'no-user@bar.com' } )
    ->status_is(204, "returns 204 even if the user doesn't exist");

  $t->post_ok('/reset_password', json => { email => 'foo@bar.com' } )
    ->status_is(204, '204 when the user does exist');
};

done_testing();
