package Test::Conch;

use v5.26;
use Mojo::Base 'Test::Mojo', -signatures;

use Test::More ();
use Test::ConchTmpDB ();
use Conch::DB;
use Test::Conch::Fixtures;
use JSON::Validator;
use Path::Tiny;
use Test::Deep ();

=pod

=head1 DESCRIPTION

Takes care of setting up a Test::Mojo with the Conch application pre-configured.

Includes JSON validation ability via L<Test::MojoSchema>.

    my $t = Test::Conch->new();
    $t->get_ok("/")->status_is(200)->json_schema_is("Whatever");

=head2 pg

Override with your own Test::PostgreSQL object if you want to use a custom database, perhaps
with extra settings or loaded with additional data.  Defaults to the basic database created by
L<Test::ConchTmpDB/mk_tmp_db>.

This is the attribute to copy if you want multiple Test::Conch objects to be able to talk to
the same database.

=cut

has 'pg';   # this is generally a Test::PostgreSQL object

=head2 validator

=cut

has 'validator' => sub {
    my $spec_file = "json-schema/response.yaml";
    die("OpenAPI spec file '$spec_file' doesn't exist.")
        unless -e $spec_file;

    my $validator = JSON::Validator->new;
    $validator->schema($spec_file);

    $validator;
};

=head2 fixtures

Provides access to the fixtures defined in Test::Conch::Fixtures.
See L</load_fixture>.

=cut

has fixtures => sub ($self) {
    Test::Conch::Fixtures->new(
        schema => $self->app->schema,
        no_transactions => 1,   # we need to use multiple db connections at once
        # currently no hooks from Test::Conch::new for adding new definitions; see add_fixture.
    );
};

=head2 new

Constructor. Takes the following arguments:

  * pg (optional). uses this as the postgres db.
  * legacy_db (optional, defaults to false).
    When false, adds no data and starts off with sql/schema.sql.
    When true, use Test::ConchTmpDB::mk_tmp_db to set up database (uses migration files,
    creates a conch user).

=cut

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

    my $pg = $args->{pg} // ($args->{legacy_db} ? Test::ConchTmpDB::mk_tmp_db() : $class->init_db);
    $pg or Test::More::BAIL_OUT("failed to create test database");

    my $self = Test::Mojo->new(
        Conch => {
            pg      => $pg->uri,    # TODO: pass dsn instead of uri
            secrets => ["********"]
        }
    );

    bless($self, $class);
    $self->pg($pg);

    # load all controllers, to find syntax errors sooner
    # (hypnotoad does this at startup, but in tests controllers only get loaded as needed)
    path('lib/Conch/Controller')->visit(
        sub {
            my $file = shift;
            return if not -f $file;
            return if $file !~ /\.pm$/; # skip swap files
            $self->app->log->info("loading $file");
            eval "require './$file'" or die $@;
        },
        { recurse => 1 },
    );

    return $self;
}

sub DESTROY ($self) {

    # ensure that a new Test::Conch instance creates a brand new Mojo::Pg connection (with a
    # possibly-different dsn) rather than using the old one to a now-dead postgres instance
    Conch::Pg->DESTROY;
}

=head2 init_db

Sets up the database for testing, using the final schema rather than running migrations.
No data is added -- you must load all desired fixtures.

Note that the Test::PostgreSQL object must stay in scope for the duration of your tests.
Returns the Conch::DB object as well when called in list context.

=cut

sub init_db ($class) {
    my $pgsql = Test::PostgreSQL->new(pg_config => 'client_encoding=UTF-8');
    die $Test::PostgreSQL::errstr if not $pgsql;

    my $schema = Conch::DB->connect(
        $pgsql->dsn, 'postgres', '',
        {
            # same as from Mojo::Pg->new($uri)->options
            AutoCommit          => 1,
            AutoInactiveDestroy => 1,
            PrintError          => 0,
            PrintWarn           => 0,
            RaiseError          => 1,
        },
    );

    Test::More::note('initializing database with sql/schema.sql...');

    $schema->storage->dbh_do(sub {
        my ($storage, $dbh, @args) = @_;
        $dbh->do('CREATE ROLE conch LOGIN');
        $dbh->do('CREATE DATABASE conch OWNER conch');
        $dbh->do(path('sql/schema.sql')->slurp_utf8) or BAIL_OUT("Test SQL load failed in $_");
        $dbh->do('RESET search_path');  # go back to "$user", public
    });

    return wantarray ? ($pgsql, $schema) : $pgsql;
}

=head2 location_is

Stolen from Test::Mojo's examples. I don't know why this isn't just part of the interface!

=cut

sub location_is ($t, $value, $desc = 'location header') {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return $t->success(Test::More->builder->is_eq($t->tx->res->headers->location, $value, $desc));
}

=head2 json_schema_is

Adds a method 'json_schema_is` to validate the JSON response of
the most recent request. If given a string, looks up the schema in
#/definitions in the JSON Schema spec to validate. If given a hash, uses
the hash as the schema to validate.

=cut

sub json_schema_is ($self, $schema) {
    my @errors;
    return $self->_test( 'fail', 'No request has been made' ) unless $self->tx;
    my $json = $self->tx->res->json;
    return $self->_test( 'fail', 'No JSON in response' ) unless $json;

    if ( ref $schema eq 'HASH' ) {
        @errors = $self->validator->validate( $json, $schema );
    }
    else {
        my $component_schema = $self->validator->get("/definitions/$schema");
        return $self->_test( 'fail',
            "Component schema '$schema' is not defined in JSON schema " )
            unless $component_schema;
        @errors = $self->validator->validate( $json, $component_schema );
    }

    my $error_count = @errors;
    my $req         = $self->tx->req->method . ' ' . $self->tx->req->url->path;
    return $self->_test( 'ok', !$error_count,
        'JSON response has no schema validation errors' )->or(
        sub {
            Test::More::diag( $error_count
                    . " Error(s) occurred when validating $req with schema "
                    . "$schema':\n\t"
                    . join( "\n\t", @errors ) );
            0;
        }
    );
}

=head2 json_cmp_deeply

Like json_is, but uses Test::Deep::cmp_deeply for the comparison instead of Test::More::is_deep.
This allows for more flexibility in how we test various parts of the data.

=cut

sub json_cmp_deeply {
    my $self = shift;
    my ($p, $data) = @_ > 1 ? (shift, shift) : ('', shift);
    my $desc = Test::Mojo::_desc(shift, qq{cmp_deeply match for JSON Pointer "$p"});
    return $self->_test('Test::Deep::cmp_deeply', $self->tx->res->json($p), $data, $desc);
}

=head2 load_validation_plans

Takes an array ref of structured hash refs and creates a validation plan (if it doesn't
exist) and adds specified validation plans for each of the structured hashes.

Each hash has the structure

	{
		name        => 'Validation plan name',
		description => 'Validation plan description',
		validations => [
			{ name => 'validation_name', version => 1 }
		]
	}

If a validation plan by the name already exists, all associations to
validations are dropped before the specified validations are added. This allows
modifying the membership of the validation plans.

Returns the list of validations plan objects.

=cut

use Conch::Models;

sub load_validation_plans ($self, $plans) {
	my @plans;
	for my $p ( $plans->@* ) {
		my $plan = Conch::Model::ValidationPlan->lookup_by_name( $p->{name} );

		unless ($plan) {
			$plan =
				Conch::Model::ValidationPlan->create( $p->{name}, $p->{description}, );
			$self->app->log->info('Created validation plan ' . $plan->name);
		}
		$plan->drop_validations;
		for my $v ( $p->{validations}->@* ) {
			my $validation =
				Conch::Model::Validation->lookup_by_name_and_version( $v->{name},
				$v->{version} );
			if ($validation) {
				$plan->add_validation($validation);
			}
			else {
				$self->app->log->info(
					"Could not find Validation name $v->{name}, version $v->{version}"
						. ' to load for ' . $plan->name);
			}
		}
		$self->app->log->info('Loaded validation plan ' . $plan->name);
		push @plans, $plan;
	}
	return @plans;
}

=head2 load_fixture

Populate the database with one or more fixtures.

=cut

sub load_fixture ($self, @fixture_names) {
    $self->fixtures->load(@fixture_names);
}

=head2 add_fixture

Add one or more fixture definition(s), and populate the database with it.

=cut

sub add_fixture ($self, %fixture_definitions) {
    $self->fixtures->add_definition(%fixture_definitions);
    $self->fixtures->load(keys %fixture_definitions);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
