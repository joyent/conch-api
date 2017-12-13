package Mojo::Conch::Route::Relay;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw( relay_routes);

use DDP;

sub relay_routes {
  my $r = shift;

  $r->get('/relay/:id/register')->to('relay#register');
}

1;

