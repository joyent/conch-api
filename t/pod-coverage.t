use strict;
use warnings;
use Test::More;
use Test::Pod::Coverage 1.00;

# if a module's parent documents a method that is redefined, let it pass
my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };

all_pod_coverage_ok($trustparents);
