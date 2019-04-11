use Test::More;
use strict;
use warnings;
use utf8;

use_ok('Conch::UUID');

use Conch::UUID 'is_uuid';

ok(   is_uuid('00000000-0000-0000-0000-000000000000'), 'all zero UUID valid');
ok( ! is_uuid('00000000-0000-0000-0000-00000000000'),  'wrong number of digits invalid');
ok(   is_uuid('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA'), 'all character UUID valid');
ok(   is_uuid('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 'all lower character UUID valid');
ok(   is_uuid('235D562B-EE0F-4381-9CCB-14D3A38430BD'), 'random UUID valid');

# can you spot the non-ascii character? me neither. but that first B is not actually
# LATIN CAPITAL LETTER B but GREEK CAPITAL LETTER BETA.
ok( ! is_uuid('235D562Β-EE0F-4381-9CCB-14D3A38430BD'), 'non-ascii alpha chars are not valid');

# that first 8 is not actually ASCII DIGIT EIGHT, but BENGALI DIGIT FOUR.
ok( ! is_uuid('৪35D562B-EE0F-4381-9CCB-14D3A38430BD'), 'non-ascii digits are not valid');

done_testing();
