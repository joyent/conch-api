use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::Status;

ok( request('/status')->is_success, 'Request should succeed' );
done_testing();
