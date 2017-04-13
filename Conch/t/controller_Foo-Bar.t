use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Conch';
use Conch::Controller::Foo::Bar;

ok( request('/foo/bar')->is_success, 'Request should succeed' );
done_testing();
