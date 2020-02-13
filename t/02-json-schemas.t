use strict;
use warnings;

use Test::More;
use YAML::PP;
use Path::Tiny;
use JSON::Schema::Draft201909;

use constant SPEC_URL => 'https://json-schema.org/draft/2019-09/schema';

diag 'using JSON::Schema::Draft201909 '.JSON::Schema::Draft201909->VERSION;

my $yaml = YAML::PP->new(boolean => 'JSON::PP');
my $js = JSON::Schema::Draft201909->new(
  output_format => 'basic',
  validate_formats => 1,
  collect_annotations => 0,
  max_traversal_depth => 56,  # needed for other.yaml
);

my $encoder = JSON::MaybeXS->new(allow_nonref => 1, utf8 => 0, convert_blessed => 1, canonical => 1, pretty => 1);

my @files;
foreach my $filename (split /\n/, `git ls-files json-schema`) {
  diag('skipping '.$filename), next if $filename =~ /^\./ or $filename !~ /yaml$/;
  my $path = path($filename);
  $js->add_schema($path->basename, $yaml->load_file($filename));
  push @files, $path->basename;
}

my $pass = 1;
foreach my $filename (@files) {
  my $result = $js->evaluate(scalar $js->get($filename), SPEC_URL);
  ok($result, 'no errors validating json-schema/'.$filename);
  next if $result;
  diag(explain($result->TO_JSON->{errors}));
  $pass = 0;
}

BAIL_OUT('json schemas have errors') if not $pass;
done_testing;
