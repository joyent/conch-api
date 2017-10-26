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
subtest 'Device setup' => sub {
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


my $test_device_id;

subtest 'List device IDs in workspaces' => sub {
  my $res = $test->request(
    GET "/workspace/$global_workspace_id/device",
    Cookie => $session
  );
  is( $res->code, 200, "[GET /workspace/$global_workspace_id/device] successful" )
    or diag( $res->content );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY' );
  $test_device_id = $res_body->[0];
  for my $device_id ( @{$res_body}) {
    is(ref $device_id, '', 'Device ID is a string' ) or last;
  }
};

subtest 'List full devices in workspaces' => sub {
  my $res = $test->request(
    GET "/workspace/$global_workspace_id/device?full=1",
    Cookie => $session
  );
  is( $res->code, 200, "[GET /workspace/$global_workspace_id/device] successful" )
    or diag( $res->content );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY' );
  for my $device ( @{$res_body}) {
    isa_ok($device, 'HASH', 'Device is an object') or last;
  }
};

subtest 'List active devices in workspaces' => sub {
  my $res = $test->request(
    GET "/workspace/$global_workspace_id/device/active",
    Cookie => $session
  );
  is( $res->code, 200, "[GET /workspace/$global_workspace_id/device/active] successful" )
    or diag( $res->content );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY' );
  for my $device ( @{$res_body} ) {
    isa_ok($device, 'HASH', 'Device is an object') or last;
  }
};

subtest 'List passing devices in workspaces' => sub {
  my $res = $test->request(
    GET "/workspace/$global_workspace_id/device/health/PASS",
    Cookie => $session
  );
  is( $res->code, 200, "[GET /workspace/$global_workspace_id/device/health/PASS] successful" )
    or diag( $res->content );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY' );
  for my $device ( @{$res_body}) {
    isa_ok($device, 'HASH', 'Device is an object') or last;
  }
};

subtest 'List failing devices in workspaces' => sub {
  my $res = $test->request(
    GET "/workspace/$global_workspace_id/device/health/FAIL",
    Cookie => $session
  );
  is( $res->code, 200, "[GET /workspace/$global_workspace_id/device/health/FAIL] successful" )
    or diag( $res->content );
  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY' );
  for my $device ( @{$res_body}) {
    isa_ok($device, 'HASH', 'Device is an object') or last;
  }
};

subtest 'Get single device' => sub {
  if( ok(defined $test_device_id, 'There is at least one device available for testing') ) {
    my $res = $test->request(
      GET "/device/$test_device_id",
      Cookie => $session
    );
    is( $res->code, 200, "[GET /device/$test_device_id] successful" )
      or diag( $res->content );
    my $res_body = decode_json $res->content;
    isa_ok( $res_body, 'HASH' );
  }
};


done_testing;
