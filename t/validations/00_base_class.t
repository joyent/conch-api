use Mojo::Base -strict;
use DDP;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Conch::Log;
use Conch::Validation;
use Conch::DB;
use Conch::Models;

my $l = Conch::Log->new(path => 'log/t-00_base_class.log');

my $device = Conch::Model::Device->new;

# SUMMARY
# =======
#
# These tests are for the core functionality of Conch::Validation. It tests
# each of the component pieces of the module are working as expected. In
# general, if Conch::Validation is changed, corresponding tests should be
# added.


{
	package Conch::Validation::Core;
	use Mojo::Base 'Conch::Validation';
	use constant name => 'name';
	use constant version => 'version';
	use constant description => 'description';
	use constant category => 'category';
}

subtest '->validate' => sub {
	like(
		exception {
			my $base_validation = Conch::Validation::Core->new(log => $l, device => $device);
			$base_validation->validate( {} );
		},
		qr/Validations must implement the `validate` method in subclass/
	);
};

subtest '->fail' => sub {
	my $base_validation = Conch::Validation::Core->new(log => $l, device => $device);
	$base_validation->fail('Validation failure');
	is( $base_validation->validation_result(0)->{message},
		'Validation failure' );
	is( scalar $base_validation->validation_results, 1 );
	is( scalar $base_validation->failures,           1 );
	is( scalar $base_validation->successes,          0 );
};

subtest '->die' => sub {
	my $base_validation = Conch::Validation::Core->new(log => $l, device => $device);

	cmp_deeply(
		exception { $base_validation->die( 'Validation dies', hint => 'how to fix' ); },
		all(
			isa('Conch::ValidationError'),
			methods(
				message => 'Validation dies',
				hint	=> 'how to fix',
				error_loc => re(qr/Exception raised in 'main' at line \d+/),
			),
		),
		'got the right validation errors',
	);
};

subtest '->clear_results' => sub {
	my $base_validation = Conch::Validation::Core->new(log => $l, device => $device);
	$base_validation->fail('Validation fail 1');
	$base_validation->fail('Validation fail 2');
	is( scalar $base_validation->validation_results, 2, 'Results collect' );
	is( scalar $base_validation->failures,           2 );
	is( scalar $base_validation->successes,          0 );

	$base_validation->clear_results;
	is( scalar $base_validation->validation_results, 0, 'Results clear' );
	is( scalar $base_validation->failures,           0 );
	is( scalar $base_validation->successes,          0 );
};

subtest '->register_result' => sub {
	my $base_validation = Conch::Validation::Core->new(log => $l, device => $device);

	like exception { $base_validation->register_result() },
	qr/'expected' value must be defined/;

	like exception {
		$base_validation->register_result( got => [ 1, 2 ], expected => 1 )
	},
	qr/must be a scalar/;

	like exception {
		$base_validation->register_result( got => 1, expected => [ 1, 2 ] )
	},
	qr/must be a scalar when comparing with 'eq'/;

	like exception {
		$base_validation->register_result( got => 1, expected => { a => 1 } )
	},
	qr/must be a scalar when comparing with 'eq'/;

	$base_validation->clear_results;

	$base_validation->register_result( expected => 'test', got => 'test', hint => 'hi' );

	cmp_deeply(
		[ $base_validation->successes ],
		[
			superhashof({
				message => "Expected eq 'test'. Got 'test'.",
				hint => undef,
			}),
		],
		'Successful result',
	);

	$base_validation->register_result( expected => 'test', got => 'bad', hint => 'hi' );
	cmp_deeply(
		[ $base_validation->failures ],
		[
			superhashof({
				message => "Expected eq 'test'. Got 'bad'.",
				hint => 'hi',
			}),
		],
		'Failed result',
	);

	$base_validation->register_result(
		expected => 'test',
		got      => 'good',
		cmp      => 'ne',
		hint     => 'hi',
	),
	cmp_deeply(
		[ $base_validation->successes ],
		[
			ignore,
			superhashof({
				message => "Expected ne 'test'. Got 'good'.",
				hint => undef,
			}),
		],
		'Successful result',
	);
	$base_validation->clear_results;

	$base_validation->register_result(
		expected => 20,
		got      => 40,
		cmp      => '>',
		hint     => 'hi',
	);
	cmp_deeply(
		[ $base_validation->successes ],
		[
			superhashof({
				message => "Expected a value > '20'. Passed.",
				hint => undef,
			}),
		],
		'Successful comparison result',
	);

	$base_validation->register_result(
		expected => 20,
		got      => 40,
		cmp      => '<',
		hint     => 'hi',
	);
	cmp_deeply(
		[ $base_validation->failures ],
		[
			superhashof({
				message => "Expected a value < '20'. Failed.",
				hint => 'hi',
			}),
		],
		'Failing comparison result',
	);

	$base_validation->clear_results;

	$base_validation->register_result(
		expected => [ 'a', 'b', 'c' ],
		got      => 'b',
		cmp      => 'oneOf',
		hint     => 'hi',
	);
	cmp_deeply(
		[ $base_validation->successes ],
		[
			superhashof({
				message => "Expected one of: 'a', 'b', 'c'. Got 'b'.",
				hint => undef,
			}),
		],
		'Successful oneOf result',
	);

	$base_validation->register_result(
		expected => [ 'a', 'b', 'c' ],
		got      => 'bad',
		cmp      => 'oneOf',
		hint     => 'hi',
	);
	cmp_deeply(
		[ $base_validation->failures ],
		[
			superhashof({
				message => "Expected one of: 'a', 'b', 'c'. Got 'bad'.",
				hint => 'hi',
			}),
		],
		'Failing oneOf result',
	);

	$base_validation->clear_results;

	$base_validation->register_result(
		expected => qr/\w{3}\d{3}/,
		got      => 'foo123',
		cmp      => 'like',
		hint     => 'hi',
	);
	cmp_deeply(
		[ $base_validation->successes ],
		[
			superhashof({
				message => 'Expected like \'(?^:\w{3}\d{3})\'. Got \'foo123\'.',
				hint => undef,
			}),
		],
		'Successful like result',
	);

	$base_validation->register_result(
		expected => qr/\w{3}\d{3}/,
		got      => 'bad42',
		cmp      => 'like',
		hint     => 'hi',
	);
	cmp_deeply(
		[ $base_validation->failures ],
		[
			superhashof({
				message => 'Expected like \'(?^:\w{3}\d{3})\'. Got \'bad42\'.',
				hint => 'hi',
			}),
		],
		'Failing like result',
	);
};

done_testing();
