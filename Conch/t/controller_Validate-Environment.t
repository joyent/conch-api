use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::Validate::Environment;

ok( request('/validate/environment')->is_success, 'Request should succeed' );
done_testing();
