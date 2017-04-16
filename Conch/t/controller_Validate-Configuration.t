use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::Validate::Configuration;

ok( request('/validate/configuration')->is_success, 'Request should succeed' );
done_testing();
