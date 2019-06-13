use strict;
use warnings;
use warnings FATAL => 'utf8';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;

use Conch::UUID qw(is_uuid create_uuid_str);

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

unlike('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', Conch::UUID::UUID_FORMAT,
    'main regex does not accept upper-cased characters');

like('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', Conch::UUID::UUID_FORMAT_LAX,
    '...but there is a lax regex that does');

like(create_uuid_str(), Conch::UUID::UUID_FORMAT, 'newly-created string matches the main regex');

ok(is_uuid(create_uuid_str()), 'is_uuid accepts uuids created by ourselves');

done_testing;
