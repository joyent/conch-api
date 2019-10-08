use strict;
use warnings;

use Test::More;
use Test::Warnings;
plan skip_all => 'no .git: cannot check dirty files' if not -d '.git';

system(qw(make ghdocs));

chomp(my $dirty = `git status --untracked --porcelain docs`);
my @errors = grep /^.[^ ]/, split("\n", $dirty);

is(@errors, 0, 'no files changed after running "make ghdocs"')
    or diag 'files need updating:',"\n",join("\n",@errors);

done_testing;
