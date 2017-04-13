use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::Ingest;

ok( request('/ingest')->is_success, 'Request should succeed' );
done_testing();
