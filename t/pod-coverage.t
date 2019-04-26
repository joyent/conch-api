use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Pod::Coverage 1.00;
use List::Util 'any';

# add regexes of module names here that should be skipped in their entirety.
my @skip_modules = (
    qr/^Conch::Validation::/,
);

# regexps of sub names that are always trusted
my @also_private = qw(
    BUILDARGS
);

# module => [ regexps of sub names to be trusted ]
my %trustme = (
);

for my $module (all_modules()) {
    next if any { $module =~ $_ } @skip_modules;

    pod_coverage_ok(
        $module,
        {
            # if a module's parent documents a method that is redefined, let it pass
            coverage_class => 'Pod::Coverage::CountParents',
            also_private   => \@also_private,
            trustme        => $trustme{$module} || [],
        },
        "pod coverage for $module"
    );
}

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
