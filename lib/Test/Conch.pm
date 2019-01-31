package Test::Conch;

use v5.26;
use Mojo::Base 'Test::Mojo', -signatures;

use Test::More ();
use Test::PostgreSQL;
use Conch::DB;
use Test::Conch::Fixtures;
use JSON::Validator;
use Path::Tiny;
use Test::Deep ();
use Mojo::Util 'trim';
use Module::Runtime 'require_module';
use List::Util 'maxstr';

=pod

=head1 DESCRIPTION

Takes care of setting up a Test::Mojo with the Conch application pre-configured.

Includes JSON validation ability via L<Test::MojoSchema>.

    my $t = Test::Conch->new();
    $t->get_ok("/")->status_is(200)->json_schema_is("Whatever");

=head1 CONSTANTS

=cut

# see also the 'conch_user' fixture in Test::Conch::Fixtures
use constant CONCH_USER => 'conch';
use constant CONCH_EMAIL => 'conch@conch.joyent.us';
use constant CONCH_PASSWORD => 'conch';

=head1 METHODS

=head2 pg

Override with your own Test::PostgreSQL object if you want to use a custom database, perhaps
with extra settings or loaded with additional data.

This is the attribute to copy if you want multiple Test::Conch objects to be able to talk to
the same database.

=cut

has 'pg';   # Test::PostgreSQL object

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

An empty database is created, using the schema in sql/schema.sql.

=cut

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

    my $pg = $args->{pg} // $class->init_db;
    $pg or Test::More::BAIL_OUT("failed to create test database");

    my $self = Test::Mojo->new(
        Conch => {
            database => {
                dsn => $pg->dsn,
                username => $pg->dbowner,
            },

            secrets => ["********"],
        }
    );

    bless($self, $class);
    $self->pg($pg);

    # load all controllers, to find syntax errors sooner
    # (hypnotoad does this at startup, but in tests controllers only get loaded as needed)
    path('lib/Conch/Controller')->visit(
        sub ($file, $) {
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
    # explicitly disconnect before terminating the server, to avoid exceptions like:
    # "DBI Exception: DBD::Pg::st DESTROY failed: FATAL:  terminating connection due to administrator command"
    do { $_->disconnect if $_->connected }
        foreach $self->app->rw_schema->storage, $self->app->ro_schema->storage;
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
        $pgsql->dsn, $pgsql->dbowner, undef,
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

    $schema->storage->dbh_do(sub ($storage, $dbh, @args) {
        $dbh->do('CREATE ROLE conch LOGIN');
        $dbh->do('CREATE DATABASE conch OWNER conch');
        $dbh->do(path('sql/schema.sql')->slurp_utf8) or BAIL_OUT('SQL load failed in sql/schema.sql');
        $dbh->do('RESET search_path');  # go back to "$user", public

        state $migration = maxstr(map { m{^sql/migrations/(\d+)-}g } glob('sql/migrations/*.sql'));
        $dbh->do('insert into migration (id) values (?)', {}, $migration);
    });

    return wantarray ? ($pgsql, $schema) : $pgsql;
}

=head2 ro_schema

Returns a read-only connection to a Test::PostgreSQL instance.

=cut

sub ro_schema ($class, $pgsql) {
    # see L<DBIx::Class::Storage::DBI/DBIx::Class and AutoCommit>
    local $ENV{DBIC_UNSAFE_AUTOCOMMIT_OK} = 1;
    Conch::DB->connect(
        $pgsql->dsn, $pgsql->dbowner, undef,
        +{
            AutoCommit          => 0,
            AutoInactiveDestroy => 1,
            PrintError          => 0,
            PrintWarn           => 0,
            RaiseError          => 1,
            ReadOnly            => 1,
        },
    );
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

Each hash has the structure:

    {
        name        => 'Validation plan name',
        description => 'Validation plan description',
        validations => [
            'Conch::Validation::Foo',
            'Conch::Validation::Bar',
        ]
    }

If a validation plan by the name already exists, all associations to
validations are dropped before the specified validations are added. This allows
modifying the membership of the validation plans.

Returns the list of validations plan objects.

=cut

sub load_validation_plans ($self, $plans) {
    my @plans;

    for my $plan_data ($plans->@*) {
        my $plan = $self->app->db_validation_plans->active->search({ name => $plan_data->{name} })->single;
        unless ($plan) {
            $plan = $self->app->db_validation_plans->create({ $plan_data->%{qw(name description)} });
            $self->app->log->info('Created validation plan ' . $plan->name);
        }

        $plan->delete_related('validation_plan_members');
        foreach my $module ($plan_data->{validations}->@*) {
            my $validation = $self->load_validation($module);
            $plan->add_to_validations($validation);
        }
        $self->app->log->info('Loaded validation plan ' . $plan->name);
        push @plans, $self->app->db_ro_validation_plans->find($plan->id);
    }
    return @plans;
}

=head2 load_validation

Add data for a validator module to the database, if it does not already exist.

=cut

sub load_validation ($self, $module) {
    my $validation = $self->app->db_ro_validations->active->search({ module => $module })->single;
    return $validation if $validation;

    require_module($module);

    $validation = $self->app->db_validations->create({
        name => $module->name,
        version => $module->version,
        description => trim($module->description),
        module => $module,
    });
    return $self->app->db_ro_validations->find($validation->id);
}

=head2 load_fixture

Populate the database with one or more fixtures.
Returns the objects that were explicitly requested.

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

=head2 load_fixture_set

Generates a set of fixtures by name and optional arguments, then loads them into the database.
See L<Test::Conch::Fixtures/generate_set> for available sets.

=cut

sub load_fixture_set ($self, $fixture_set_name, @args) {
    my @fixture_names = $self->fixtures->generate_set($fixture_set_name, @args);
    $self->fixtures->load(@fixture_names);
}

=head2 generate_fixtures

Generate fixture definition(s) using generic data, and any necessary dependencies, and populate
the database with them.

Not-nullable fields are filled in with sensible defaults, but all may be overridden.

e.g.:

    $t->generate_fixture_definitions(
        device_location => { rack_unit => 3 },
        datacenter_rack_layouts => [
            { rack_unit_start => 1 },
            { rack_unit_start => 2 },
            { rack_unit_start => 3 },
        ],
    );

See L<Test::Conch::Fixtures/_generate_definition> for the list of recognized types.

=cut

sub generate_fixtures ($self, %specification) {
    state $unique_num = 1000;
    my @fixture_names = $self->fixtures->generate_definitions($unique_num++, %specification);
    return if not @fixture_names;
    $self->fixtures->load(@fixture_names);
}

=head2 authenticate

Authenticates a user in the current test instance. Uses default credentials if not provided.
Optionally will bail out of *all* tests on failure.

=cut

sub authenticate ($self, %args) {
    $args{bailout} //= 1 if not $args{user};
    $args{user} //= CONCH_EMAIL;
    $args{password} //= CONCH_PASSWORD;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->post_ok('/login', json => { %args{qw(user password)} })
        ->status_is(200, $args{message});

    if ($self->tx->res->code != 200) {
        my $message = 'Login failed for '.$args{user};
        Test::More::BAIL_OUT($message) if $args{bailout};
        Test::More::plan(skip_all => $message) if not $args{bailout};
    }

    return $self;
}

=head2 txn_local

Given a subref, execute the code inside a transaction that is rolled back at the end. Useful
for testing with mutated data that should not affect other tests.  The subref is called as a
subtest and is invoked with the test object as well as any additional provided arguments.

=cut

sub txn_local ($self, $test_name, $subref, @args) {
    $self->app->schema->txn_begin;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::subtest($test_name => $subref, $self, @args);

    $self->app->schema->txn_rollback;
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
