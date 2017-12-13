#!/usr/bin/env carton exec plackup

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Log::Log4perl;
use Data::Printer;
use Mojo::Server::PSGI;
Log::Log4perl::init($ENV{CONCH_LOG_CONF} || './log4perl.conf');

use Conch;

use Plack::Builder;

my $dancer_app = Conch->to_app;
my $mojo_app = Mojo::Server::PSGI->new;
$mojo_app->load_app("bin/mojo");

builder {
    enable 'Deflater';
    sub {
      my $env = shift;
      my $res = $dancer_app->($env);
      my $foo = ref $res;
      if (ref $res eq 'ARRAY' && $res->[0] == 404 ) {
        my $fallback_res = $mojo_app->run($env);
        return $fallback_res if $fallback_res->[0] != 404;
      }
      return $res;
    };
}
