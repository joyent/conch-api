package Conch::Route::Relay;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw( relay_routes);

use DDP;

sub relay_routes {
  my $r = shift;

  $r->post('/relay/:id/register')->to('relay#register');
}

1;

