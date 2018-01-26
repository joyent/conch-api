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

my $now = $pg->db->query('SELECT NOW()::timestamptz as now ')->hash->{now};
ok(Conch::Time->new($now));

my $dt = $pg->db->query("SELECT '2018-01-02'::timestamptz as datetime")->hash->{datetime};
ok(Conch::Time->new($dt));
is(Conch::Time->new($dt)->to_string, '2018-01-02T00:00:00.000Z', 'Formats datetime string as RFC 3339');
is(''.Conch::Time->new($dt), '2018-01-02T00:00:00.000Z', 'Overloads conversion to string');

ok(Conch::Time->new($dt) eq Conch::Time->new($dt), 'Equal to Conch::Time with same datetime');
is(Conch::Time->new($now), Conch::Time->new($now));

ok(Conch::Time->new($now) ne Conch::Time->new($dt), 'Different datetimes not equal');
isnt(Conch::Time->new($dt), Conch::Time->new($now));


done_testing();
