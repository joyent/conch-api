use strict;
use warnings;

use Conch;

my $app = Conch->apply_default_middlewares(Conch->psgi_app);
$app;

