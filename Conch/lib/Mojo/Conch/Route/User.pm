package Mojo::Conch::Route::User;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw( user_routes);

use DDP;

sub user_routes {
  my $r = shift;

  $r->get('/settings')->to('user#get_settings');
  $r->post('/settings')->to('user#set_settings');

  $r->get('/settings/:key')->to('user#get_setting');
  $r->post('/settings/:key')->to('user#set_setting');
  $r->delete('/settings/:key')->to('user#delete_setting');
}

1;

