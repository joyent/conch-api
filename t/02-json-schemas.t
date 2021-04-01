use strict;
use warnings;

use experimental 'signatures';
use Test::More;
use YAML::PP;
use Path::Tiny;
use Try::Tiny;
use JSON::Schema::Draft201909 0.024;
use JSON::Schema::Draft201909::Utilities 'canonical_schema_uri';

diag 'using JSON::Schema::Draft201909 '.JSON::Schema::Draft201909->VERSION;

my $yaml = YAML::PP->new(boolean => 'JSON::PP');
my $js = JSON::Schema::Draft201909->new(
  output_format => 'terse',
  validate_formats => 1,
  max_traversal_depth => 67,  # needed for other.yaml
);

my $encoder = JSON::MaybeXS->new(allow_nonref => 1, utf8 => 0, convert_blessed => 1, canonical => 1, pretty => 1);

my @files;
foreach my $filename (split /\n/, `git ls-files json-schema`) {
  diag('skipping '.$filename), next if $filename =~ /^\./ or $filename !~ /yaml$/;
  my $path = path($filename);
  try {
    $js->add_schema($path->basename, $yaml->load_file($filename));
  }
  catch {
    die "$filename is not parseable: ", explain($_->TO_JSON);
  };
  push @files, $path->basename;
}

# simple substitution for the real schema that is stored in the database
$js->add_schema('/json_schema/hardware_product/specification/latest', { type => 'object' });

my $pass = 1;
foreach my $filename (@files) {
  my $schema = $js->get($filename);

  my $result = $js->evaluate($schema, 'draft-2019-09-strict.yaml');
  ok($result, 'no errors validating json-schema/'.$filename.' against draft-2019-09-strict.yaml');

  if (not $result) {
    diag(explain($result->TO_JSON->{errors}));
    $pass = 0;
  }
  else {
    my $base = Mojo::URL->new($filename);
    foreach my $name (sort keys $schema->{'$defs'}->%*) {
      my $schema = $schema->{'$defs'}{$name};

      my @refs;
      JSON::Schema::Draft201909->new->traverse($schema, {
        callbacks => {
          '$ref' => sub ($schema, $state) {
            push @refs, Mojo::URL->new($schema->{'$ref'})->to_abs(canonical_schema_uri($state));
          }
        },
        canonical_schema_uri => $filename,
      });

      my %seen_refs;
      while (my $ref = shift @refs) {
        next if $seen_refs{$ref}++;

        my $uri = Mojo::URL->new($ref);
        next if $uri->is_abs;   # internal references are all relative

        $uri = $uri->to_abs(Mojo::URL->new($base));
        my $def = $js->get($uri);
        if (not defined $def) {
          $result = fail('cannot find schema for '.$uri);
          next;
        }

        next if $uri eq '/json_schema/hardware_product/specification/latest';
        my @def_segments = split('/', $uri->fragment//'');
        if (@def_segments < 3 or ($def_segments[0] ne '' and $def_segments[1] ne '$defs')) {
          $result = fail('in '.$filename.', invalid uri fragment in $ref: "'.($uri->fragment//'').'"');
          next;
        }

        my $def_name = $def_segments[2];
        if (exists $schema->{'$defs'}{$def_name}) {
          $result = fail('namespace collision: '.$uri.' conflicts with pre-existing '.$def_name.' definition');
          next;
        }
        $schema->{'$defs'}{$def_name} = $def;
        JSON::Schema::Draft201909->new->traverse($def, {
          callbacks => { '$ref' => sub ($schema, $state) {
              push @refs, Mojo::URL->new($schema->{'$ref'})->to_abs(canonical_schema_uri($state));
            } },
          canonical_schema_uri => $uri,
        });
      }
    }
    pass('checked all $refs in '.$filename);
  }

  $pass = 0 if not $result;
  next if $result;
}

BAIL_OUT('json schemas have errors') if not $pass;
done_testing;
