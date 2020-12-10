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

    my @trustme = @{$trustme{$module} // []};
    push @trustme, 'run' if $module =~ /^Conch::Command::/;

    pod_coverage_ok(
        $module,
        {
            coverage_class => 'Pod::Coverage::CountParents',
            #coverage_class => 'Pod::Coverage::TrustPod', # includes Pod::Coverage::CountParents
            also_private   => \@also_private,
            trustme        => \@trustme,
        },
        "pod coverage for $module"
    );
}

done_testing;
# vim: set sts=2 sw=2 et :
