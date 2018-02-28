use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use DDP;

use_ok("Conch::Time");
use Conch::Time;

my $pgtmp = mk_tmp_db() or die;
my $dbh   = DBI->connect( $pgtmp->dsn );
my $pg    = Mojo::Pg->new( $pgtmp->uri );

subtest 'Test timestamps from real DB' => sub {
	my $now = $pg->db->query('SELECT NOW()::timestamptz as now ')->hash->{now};
	ok( my $conch_time = Conch::Time->new($now) );
	isa_ok( $conch_time->to_datetime, 'DateTime', 'Can produce DateTime object' );

	my $dt = $pg->db->query("SELECT '2018-01-02'::timestamptz as datetime")
		->hash->{datetime};
	ok( Conch::Time->new($dt) );
	is( Conch::Time->new($dt)->to_string,
		'2018-01-02T00:00:00.000Z', 'Formats datetime string as RFC 3339' );
	is(
		'' . Conch::Time->new($dt),
		'2018-01-02T00:00:00.000Z',
		'Overloads conversion to string'
	);

	ok(
		Conch::Time->new($dt) eq Conch::Time->new($dt),
		'Equal to Conch::Time with same timestamp'
	);
	is( Conch::Time->new($now), Conch::Time->new($now) );
	ok( Conch::Time->new($now) ne Conch::Time->new($dt),
		'Different timestamps not equal' );
	isnt( Conch::Time->new($dt), Conch::Time->new($now) );
};

subtest 'Test parsing of timestamps' => sub {
	my @cases = (
		{
			input    => '2018-01-02 00:00:00+00',
			expected => '2018-01-02T00:00:00.000Z',
			message  => 'Replaces +00 timezone with Z'
		},
		{
			input    => '2018-01-02 00:00:00-00',
			expected => '2018-01-02T00:00:00.000Z',
			message  => 'Replaces -00 timezone with Z'
		},
		{
			input    => '2018-01-02 00:00:00+00:00',
			expected => '2018-01-02T00:00:00.000Z',
			message  => 'Replaces +00:00 timezone with Z'
		},
		{
			input    => '2018-01-02 00:00:00+00:00',
			expected => '2018-01-02T00:00:00.000Z',
			message  => 'Replaces -00:00 timezone with Z'
		},
		{
			input    => '2018-01-02 00:00:00+01',
			expected => '2018-01-02T00:00:00.000+01:00',
			message  => 'Appends :00 to postive timezones that do not specify minutes'
		},
		{
			input    => '2018-01-02 00:00:00-01',
			expected => '2018-01-02T00:00:00.000-01:00',
			message  => 'Appends :00 to negative timezones that do not specify minutes'
		},
		{
			input    => '2018-01-02 00:00:00+01:20',
			expected => '2018-01-02T00:00:00.000+01:20',
			message  => 'Does not modify timezones that specify minutes'
		},
		{
			input    => '2018-01-02 00:00:00+00:20',
			expected => '2018-01-02T00:00:00.000+00:20',
			message  => 'Does not modify 00 timezones that specify minutes'
		},
		{
			input    => '2018-01-02 00:00:00.987654+00',
			expected => '2018-01-02T00:00:00.988Z',
			message  => 'Microseconds rounded to milliseconds'
		},
	);

	for (@cases) {
		is( Conch::Time->new( $_->{input} )->to_string,
			$_->{expected}, $_->{message} );
	}
};

done_testing();
