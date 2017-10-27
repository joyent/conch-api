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
subtest 'Problem setup' => sub {
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

subtest 'Get device problems' => sub {
  my $res = $test->request( GET "/workspace/$global_workspace_id/problem",
    Cookie => $session );
  is( $res->code, 200,
    "[GET /workspace/$global_workspace_id/problem] successful" )
    or diag( $res->content );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'HASH', 'Response is an object' );
  ok( exists $res_body->{failing},    "Problem has failing group" );
  ok( exists $res_body->{unreported}, "Problem has unreported group" );
  ok( exists $res_body->{unlocated},  "Problem has unlocated group" );
};

done_testing;
