use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
	if $@;

# if a module's parent documents a method that is redefined, let it pass
my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };

all_pod_coverage_ok($trustparents);
