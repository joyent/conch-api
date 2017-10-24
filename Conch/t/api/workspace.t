use strict;
use warnings;

use Conch;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use JSON::XS;
use Data::Printer;
use Log::Log4perl qw(:easy);

my $app = Conch->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $jar = HTTP::Cookies->new();

subtest 'Create session' => sub {
  my $login =
    encode_json { user => $ENV{'TEST_USER'}, password => $ENV{'TEST_PW'} };
  my $res = $test->request( POST "/login", Content => $login );

  is( $res->code, 200, 'Successful login' );
  $jar->extract_cookies($res);
};

my $cookie = $jar->as_string();
$cookie =~ /^[^:]+: ([^;]+);/;
my $session = $1;

my $workspace_id;

subtest 'List workspaces' => sub {
  my $res = $test->request( GET '/workspace', Cookie => $session );
  is( $res->code, 200, '[GET /workspace] successful' );

  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY' );
  cmp_ok( scalar @{$res_body}, '>', 0, 'Array has at least one workspace' )
    or diag('The test user needs to be assigned to at least one workspace');

  for my $workspace ( @{$res_body} ) {
    ok( exists $workspace->{id},          "Workspace has id" );
    ok( exists $workspace->{name},        "Workspace has name" );
    ok( exists $workspace->{description}, "Workspace has description" );
    ok( exists $workspace->{role},        "Workspace has role" );
  }
  $workspace_id = $res_body->[0]->{id};
};

subtest 'Get single workspace' => sub {
  my $res =
    $test->request( GET "/workspace/$workspace_id", Cookie => $session );
  is( $res->code, 200, "[GET /workspace/$workspace_id] successful" )
    or diag( $res->content );

  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'HASH' );
  ok( exists $res_body->{id},          "Workspace has id" );
  ok( exists $res_body->{name},        "Workspace has name" );
  ok( exists $res_body->{description}, "Workspace has description" );
  ok( exists $res_body->{role},        "Workspace has role" );
};

my $subworkspace_id;
subtest 'Create sub-workspace' => sub {
  my @chars = ("A".."Z", "a".."z");
  my $name;
  $name .= $chars[rand @chars] for 1..8;
  my $payload = encode_json { name => $name, description => 'test workspace' };

  my $res = $test->request(
    POST "/workspace/$workspace_id/child",
    Cookie  => $session,
    Content => $payload
  );
  is( $res->code, 201, "[POST /workspace/$workspace_id/child] successful" )
    or diag( $res->content );

  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'HASH' );


  ok( exists $res_body->{id}, 'Workspace has id' );
  is( $res_body->{name}, $name, 'Workspace has specified name' );
  is( $res_body->{description}, 'test workspace',
    'Workspace has specified description'
  );
  is( $res_body->{role}, 'Administrator', 'Creater has administrator role' );

  $subworkspace_id = $res_body->{id}
};

subtest 'List sub-workspace' => sub {

  my $res = $test->request(
    GET "/workspace/$workspace_id/child",
    Cookie  => $session
  );
  is( $res->code, 200, "[GET /workspace/$workspace_id/child] successful" )
    or diag( $res->content );

  my $res_body = decode_json $res->content;
  isa_ok( $res_body, 'ARRAY' );

};

done_testing;
