use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::Validate;

ok( request('/validate')->is_success, 'Request should succeed' );
done_testing();
