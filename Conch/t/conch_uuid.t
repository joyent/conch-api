use Test::More;
use strict;
use warnings;

use_ok('Conch::UUID');

use Conch::UUID 'is_uuid';

ok(   is_uuid('00000000-0000-0000-0000-000000000000'), 'all zero UUID valid');
ok( ! is_uuid('00000000-0000-0000-0000-00000000000'),  'wrong number of digits invalid');
ok(   is_uuid('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA'), 'all character UUID valid');
ok(   is_uuid('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 'all lower character UUID valid');
ok(   is_uuid('235D562B-EE0F-4381-9CCB-14D3A38430BD'), 'random UUID valid');
ok(   is_uuid '235D562B-EE0F-4381-9CCB-14D3A38430BD',  'subroutine prototype works');

done_testing();
