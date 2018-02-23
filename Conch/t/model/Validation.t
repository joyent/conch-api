use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use DDP;
use Data::UUID;

my $uuid = Data::UUID->new;

use_ok("Conch::Model::Validation");

use Conch::Model::Validation;

my $pgtmp = mk_tmp_db() or die;
my $pg = Conch::Pg->new( $pgtmp->uri );

my $validation;
subtest "Create validation" => sub {
	$validation = Conch::Model::Validation->create( 'test', 1, 'test validation',
		'Conch::Validation::Test' );
	isa_ok( $validation, 'Conch::Model::Validation' );
	ok( $validation->id );
	is( $validation->name,        'test' );
	is( $validation->version,     1 );
	is( $validation->persistence, 0 );
	is( $validation->description, 'test validation' );
};

subtest "lookup validation" => sub {
	my $maybe_validation = Conch::Model::Validation->lookup( $uuid->create_str );
	is( $maybe_validation, undef, 'unfound validation is undef' );

	$maybe_validation = Conch::Model::Validation->lookup( $validation->id );
	is_deeply( $maybe_validation, $validation,
		'found validation is same as created' );
};

subtest "upsert validation" => sub {

	subtest "Unchanged upsert returns undef " => sub {
		my $upsert_validation =
			Conch::Model::Validation->upsert( 'test', 1, 'test validation',
			'Conch::Validation::Test' );
		ok( !defined($upsert_validation) );
	};

	subtest "Upsert existing validation" => sub {
		my $upsert_validation =
			Conch::Model::Validation->upsert( 'test', 1, 'upsert test validation',
			'Conch::Validation::Test' );
		isa_ok( $upsert_validation, 'Conch::Model::Validation' );
		is( $upsert_validation->id, $validation->id,
			'Has same ID as previous Validation' );
		is( $upsert_validation->name,        'test' );
		is( $upsert_validation->version,     1 );
		is( $upsert_validation->persistence, 0 );
		is( $upsert_validation->description, 'upsert test validation' );
	};
	subtest "Upsert new validation" => sub {

		# new version
		my $upsert_validation =
			Conch::Model::Validation->upsert( 'test', 2, 'upsert new validation',
			'Conch::Validation::Foobar' );
		isa_ok( $upsert_validation, 'Conch::Model::Validation' );
		isnt( $upsert_validation->id, $validation->id,
			'Has different ID as previous Validation' );
		is( $upsert_validation->name,        'test' );
		is( $upsert_validation->version,     2 );
		is( $upsert_validation->persistence, 0 );
		is( $upsert_validation->description, 'upsert new validation' );
	};
};

done_testing();
