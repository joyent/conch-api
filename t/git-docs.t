use strict;
use warnings;

use Test::More;
plan skip_all => 'no .git: cannot check dirty files' if not -d '.git';

system(qw(make ghdocs));

chomp(my $dirty = `git diff --name-only docs`);
is(split("\n", $dirty), 0, 'no files changed after running "make ghdocs"')
    or diag 'files need updating:',"\n",$dirty;

done_testing;
