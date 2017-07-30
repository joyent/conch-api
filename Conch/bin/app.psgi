#!/usr/bin/env carton exec plackup

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use Conch;

Conch->to_app;

use Plack::Builder;

builder {
    enable 'CrossOrigin', origins => '*';
    enable 'Deflater';
    Conch->to_app;
}



=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use Conch;
use Plack::Builder;

builder {
    enable 'Deflater';
    Conch->to_app;
}

=end comment

=cut

=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use Conch;
use Conch_admin;

builder {
    mount '/'      => Conch->to_app;
    mount '/admin'      => Conch_admin->to_app;
}

=end comment

=cut
