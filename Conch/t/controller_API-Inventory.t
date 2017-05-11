use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::API::Inventory;

ok( request('/api/inventory')->is_success, 'Request should succeed' );
done_testing();
