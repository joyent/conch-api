use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::Validate::Inventory;

ok( request('/validate/inventory')->is_success, 'Request should succeed' );
done_testing();
