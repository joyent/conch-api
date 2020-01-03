use strict;
use warnings;

use Test::Conch;
use Test::More;
use Test::Warnings;
use JSON::Validator;
use Test::Deep;
use Test::Fatal;

my $t = Test::Conch->new;

subtest '/device/:id/interface/:iface_name/:field validation' => sub {
    my $validator = $t->app->get_response_validator;
    my $schema = $validator->get('/definitions/DeviceNicField');

    cmp_deeply(
        [ $validator->validate({ device_id => 'TEST' }, $schema) ],
        [ methods(message => re(qr/should not match/i)) ],
        'device_id is not a valid response field',
    );

    cmp_deeply(
        [ $validator->validate({ created => '2018-01-02T00:00:00.000+00:20' }, $schema) ],
        [ methods(message => re(qr/not allowed/i)) ],
        'created is not a valid response field',
    );

    cmp_deeply(
        [ $validator->validate({ iface_name => 'foo' }, $schema) ],
        [],
        'iface_name is a valid response field',
    );
};

subtest 'device report validation' => sub {
    my $validator = JSON::Validator->new
        ->load_and_validate_schema('json-schema/device_report.yaml',
            { schema => 'http://json-schema.org/draft-07/schema#' });

    cmp_deeply(
        [ $validator->validate({ '' => {} },
                $validator->get('/definitions/DeviceReport_v2.38/properties/disks')) ],
        [ methods(
            path => '/',
            message => re(qr{/propertyName/ String does not match '?\^\\S\+\$'?}i),
        ) ],
        'bad disk entries are rejected',
    );
};

done_testing;
