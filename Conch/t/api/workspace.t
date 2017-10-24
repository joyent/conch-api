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

  ok( $res->is_success, 'Successful login' );
  $jar->extract_cookies($res);
};

my $cookie = $jar->as_string();
$cookie =~ /^[^:]+: ([^;]+);/;
my $session = $1;

subtest 'List workspaces' => sub {
  my $res  = $test->request( GET '/workspace', Cookie => $session );
  ok( $res->is_success, '[GET /workspace] successful' )
    or diag('Request: '. $res->message);

  my $res_body = decode_json $res->content;
  ok( $res_body, 'JSON response');
  isa_ok( $res_body, 'ARRAY');
  for my $workspace (@{ $res_body }) {
    ok( exists $workspace->{id}, "Workspace has id" );
    ok( exists $workspace->{name}, "Workspace has name" );
    ok( exists $workspace->{description}, "Workspace has description" );
    ok( exists $workspace->{role}, "Workspace has role" );
  }
};


done_testing;
