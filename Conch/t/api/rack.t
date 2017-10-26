use strict;
use warnings;

use Conch;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use JSON::XS;
use Data::Printer;
use List::Util 'first';
use Log::Log4perl qw(:easy);

my $app = Conch->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $session;
my $global_workspace_id;

# Login and get global workspace
subtest 'Rack setup' => sub {
  my $login =
    encode_json { user => $ENV{'TEST_USER'}, password => $ENV{'TEST_PW'} };
  my $res = $test->request( POST "/login", Content => $login );

  is( $res->code, 200, 'Successful login' );
  my $jar = HTTP::Cookies->new();
  $jar->extract_cookies($res);
  my $cookie = $jar->as_string();
  $cookie =~ /^[^:]+: ([^;]+);/;
  $session = $1;

  $res = $test->request( GET '/workspace', Cookie => $session );
  is( $res->code, 200, '[GET /workspace] successful' );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY' );
  cmp_ok( scalar @{$res_body}, '>', 0, 'Array has at least one workspace' )
    or diag('The test user needs to be assigned to at least one workspace');
  my $global_ws = first { $_->{name} eq 'GLOBAL' } @{$res_body};
  $global_workspace_id = $global_ws->{id};
  ok( $global_workspace_id, 'Global workspace ID' );
};

my $test_rack_id;

subtest 'Get workspace racks' => sub {
  my $res = $test->request( GET "/workspace/$global_workspace_id/rack",
    Cookie => $session );
  is( $res->code, 200, "[GET /workspace/$global_workspace_id/rack] successful" )
    or diag( $res->content );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'HASH',
    'Response is an object of racks grouped by datacenter AZ' );
  for my $az ( keys %{$res_body} ) {
    isa_ok( $res_body->{$az}, 'ARRAY', 'Array of racks' ) or last;
    $test_rack_id = $test_rack_id || $res_body->{$az}->[0]->{id};
  }
};

subtest 'Get single workspace rack' => sub {
  if ( ok( defined $test_rack_id,
      'At least one rack in a datacenter room exists in the workspace'
    ))
  {
    my $res =
      $test->request( GET "/workspace/$global_workspace_id/rack/$test_rack_id",
      Cookie => $session );
    is( $res->code, 200,
      "[GET /workspace/$global_workspace_id/rack/$test_rack_id] successful" )
      or diag( $res->content );
    my $res_body = decode_json $res->content;
    isa_ok( $res_body, 'HASH', 'Response is an rack object' );
  }
};

subtest 'Get rack roles' => sub {
  my $res = $test->request( GET "/rack-role", Cookie => $session );
  is( $res->code, 200, "[GET /rack-role] successful" )
    or diag( $res->content );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY', 'Response is an array of rack role objects' );
  for my $role ( @{$res_body} ) {
    isa_ok( $role, 'HASH', 'Rack role object' ) or last;
    ok( exists $role->{name}, 'Rack role has name' );
    ok( exists $role->{size}, 'Rack role has size' );
  }
};

done_testing;
