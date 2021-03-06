use strict;
use warnings;

use Test::Conch;
use Test::More;
use Test::Warnings;

my $t = Test::Conch->new(pg => undef);

$t->get_ok('/foo')
    ->status_is(404)
    ->json_is({ error => 'Route Not Found' });

$t->get_ok($_)
    ->status_is(404)
    ->stash_cmp_deeply('/top_level_path_match', 1)
    ->json_is({ error => 'Route Not Found' })
      foreach
        '/rack',
        '/validation',
        '/workspace';

done_testing;
# vim: set sts=2 sw=2 et :
