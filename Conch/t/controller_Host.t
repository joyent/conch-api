use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::Host;

ok( request('/host')->is_success, 'Request should succeed' );
done_testing();
