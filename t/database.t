use v5.26;
use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Conch;
use Test::Fatal;
use Test::Warnings ':all';
use Test::Memory::Cycle;
use Test::Deep;
use Conch::UUID 'create_uuid_str';
use Conch::DB::Util;
use Crypt::Eksblowfish::Bcrypt 'bcrypt';

subtest 'assert db version' => sub {
    my ($pgsql, $schema) = Test::Conch->init_db;
    my $pgsql_version = Conch::DB::Util::get_postgres_version($schema);
    diag $schema->storage->connect_info->[0].' running '.$pgsql_version;
    my ($major, $minor, $rest) = $pgsql_version =~ /PostgreSQL (\d+)\.(\d+)(\.\d+)?\b/;
    $minor //= 0;
    $rest //= '';
    require Conch::Plugin::Database;
    is($major, Conch::Plugin::Database->POSTGRES_MINIMUM_VERSION_MAJOR,
        'running postgres '.Conch::Plugin::Database->POSTGRES_MINIMUM_VERSION_MAJOR.'.x')
        and
    cmp_ok($minor, '>=', Conch::Plugin::Database->POSTGRES_MINIMUM_VERSION_MINOR,
        'running at least postgres '.Conch::Plugin::Database->POSTGRES_MINIMUM_VERSION_MAJOR
        .'.'.Conch::Plugin::Database->POSTGRES_MINIMUM_VERSION_MINOR);
};

subtest 'db connection without Conch, and data preservation' => sub {
    my ($pgsql, $schema) = Test::Conch->init_db;

    is(
        $schema->resultset('user_account')->count,
        0,
        'without Conch: new database contains no users',
    );

    my $user = $schema->resultset('user_account')->create({
        name => 'new user',
        email => 'test0@conch.joyent.us',
        password => 'whargarbl',
    });

    is(
        Test::Conch->new->app->db_user_accounts->count,
        0,
        'Conch app with no custom options gets a new database instance with no users',
    );

    cmp_deeply(
        [ Test::Conch->new(pg => $pgsql)->app->db_user_accounts->get_column('name')->all ],
        [ 'new user' ],
        'with Conch: connecting with first database handle finds the newly-created user',
    );
};

subtest 'read-only database handle' => sub {
    my $t = Test::Conch->new;

    my $user1;
    is(
        exception {
            $user1 = $t->app->db_user_accounts->create({
                name => 'new user',
                email => 'test1@conch.joyent.us',
                password => 'whargarbl',
            });
            $user1->update({ name => 'a new name' });
        },
        undef,
        'no exception creating or updating a user using the normal db handle',
    );

    like(
        $t->app->rw_schema->storage->dbh_do(sub ($storage, $dbh) {
            my ($name) = $dbh->selectrow_array('select application_name from pg_stat_activity where pid = pg_backend_pid()');
            return $name;
        }),
        qr/^conch-${\ $t->API_VERSION_RE } \($$\)$/,
        'can properly identify the query process by app and pid in pg_stat_activity',
    );

    like(
        exception {
            $t->app->db_ro_user_accounts->create({
                name => 'another new user',
                email => 'test2@conch.joyent.us',
                password => 'whargarbl',
            });
        },
        qr/permission denied for relation user_account/,
        'cannot create a user using the read-only db handle',
    );

    is(
        exception {
            $t->app->db_ro_user_accounts->find($user1->id);
        },
        undef,
        'no exception querying for a user using the read-only db handle',
    );

    like(
        $t->app->ro_schema->storage->dbh_do(sub ($storage, $dbh) {
            my ($name) = $dbh->selectrow_array('select application_name from pg_stat_activity where pid = pg_backend_pid()');
            return $name;
        }),
        qr/^conch-${\ $t->API_VERSION_RE } \($$\)$/,
        'can properly identify the query process by app and pid in pg_stat_activity',
    );

    warnings(sub {
        memory_cycle_ok($t, 'no leaks in the Test::Conch object');
    });
};

subtest 'transactions' => sub {
    my $t = Test::Conch->new;

    my $user_count = $t->app->db_user_accounts->count;

    like(
        exception {
            $t->app->schema->txn_do(sub {
                # get a "new" connection from the app here, rather than using the same $schema...
                $t->app->db_user_accounts->create({
                    name => 'another new user',
                    email => 'test2@conch.joyent.us',
                    password => 'whargarbl',
                });
                is($t->app->db_user_accounts->count, $user_count + 1, 'another user was created');
                die 'oops, belay that order';
            });
        },
        qr/oops, belay that order/,
        'caught exception from inside the transaction',
    );

    is($t->app->db_user_accounts->count, $user_count, 'the new user was rolled back');

    my $r = Mojolicious::Routes->new;
    $r->get(
        '/_test_txn_wrapper1',
        sub ($c) {
            my $result = $c->txn_wrapper(sub ($self, @args) {
                cmp_deeply(\@args, [ 'hello', 'there' ], 'got the extra argument(s)');
                $c->db_user_accounts->create({
                    name => 'another new user',
                    email => 'test2@conch.joyent.us',
                    password => 'whargarbl',
                });
                is($c->db_user_accounts->count, $user_count + 1, 'another user was created');
                die 'rollback';

            }, 'hello', 'there');
            is($result, undef, 'return value is undef in case of an exception');

            is($c->res->code, undef, 'no response code was set on intentional rollback');
            $c->rendered(200);
        },
    );

    $r->get(
        '/_test_txn_wrapper2',
        sub ($c) {
            my $user = $c->txn_wrapper(sub ($my_c, $id) {
                $my_c->db_user_accounts->create({
                    id => $id,
                    name => 'new user',
                    email => 'foo@bar',
                    password => 'foo',
                });
            }, $c->req->query_params->param('id'));

            $c->status($user ? 204 : 400);
        },
    );

    $t->add_routes($r);

    $t->get_ok('/_test_txn_wrapper1')
        ->content_is('', 'no error response was prepared on intentional rollback');

    is($t->app->db_user_accounts->count, $user_count, 'the new user was rolled back (again)');

    $t->get_ok('/_test_txn_wrapper2?id=bad_id')
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/invalid input syntax for (?:type )?uuid: "bad_id"/) });

    is($t->app->db_user_accounts->count, $user_count, 'no new user was created');

    $t->get_ok('/_test_txn_wrapper2?id='.create_uuid_str())
        ->status_is(204);

    is($t->app->db_user_accounts->count, $user_count + 1, 'one user was successfully created');
};

subtest 'multiple application instances talking to the same db' => sub {
    my $t = Test::Conch->new;
    my $new_user = $t->app->db_user_accounts->create({
        name => 'foo',
        email => 'foo@conch.joyent.us',
        password => $t->app->random_string,
    });

    my $t2 = Test::Conch->new(pg => $t->pg);
    my $new_user_copy = $t2->app->db_user_accounts->active->search({ name => 'foo' })->single;
    is($new_user->id, $new_user_copy->id, 'can obtain the user from the second test instance');
};

subtest 'get_migration_level' => sub {
    my ($pgsql, $schema) = Test::Conch->init_db;
    my ($latest_migration, $expected_latest_migration) = Conch::DB::Util::get_migration_level($schema);

    like($expected_latest_migration, qr/^0\d{3}$/, 'migration level from disk retains leading zeros');

    cmp_ok($latest_migration, '==', $expected_latest_migration,
        'migration level (numerically) matches the latest disk file because we inserted that value manually into the db');
};

subtest 'Authen::Passphrase handling' => sub {
    # generated via: Conch::DB::Result::UserAccount::_hash_password('my password');
    # (before that code was deleted)
    my $legacy_hashed_password = '$2a$04$ZDP2bkfuYFb1KxLzRkLvWeHwHTZu.D3Be9EGOvd23/EcFV0CNb0iC';

    is(
        # only need the algorithm parameters including salt (22 base64 digits after prefix)
        bcrypt('my password', substr($legacy_hashed_password, 0, 29)),
        $legacy_hashed_password,
        'verified old hashed password using direct method',
    );

    my $obj = Authen::Passphrase->from_crypt($legacy_hashed_password);
    ok($obj->match('my password'), 'Authen::Passphrase verified our old hashed password');

    my $t = Test::Conch->new;
    my $legacy_account = $t->app->db_user_accounts->new_result({
        name => 'guinea pig 2',
        email => 'baz@baz.com',
    });
    $legacy_account->store_column(password => $legacy_hashed_password);   # bypass deflator
    $legacy_account->insert;
    ok(
        $legacy_account->check_password('my password'),
        'checked password of legacy account using new helper method',
    );

    my $new_account = $t->app->db_user_accounts->create({
        name => 'King Zøg',
        email => 'zog@zog.com',
        password => 'Zøg rules, 💩 drools',
    });
    ok($new_account->password->isa('Authen::Passphrase'), 'password is an inflated object');
    ok(
        $new_account->check_password('Zøg rules, 💩 drools'),
        'unicode is ok too',
    );
};

subtest 'database constraints' => sub {
    my ($pgsql, $schema) = Test::Conch->init_db;

    my $user = $schema->resultset('user_account')->create({
        name => 'constraint check user',
        email => 'constraint@conch.joyent.us',
        password => 'whargarbl',
    });

    like(
        exception {
            $schema->resultset('build')->create({
                name => 'my first build',
                started => undef,
                completed => \'now()',
                completed_user_id => $user->id,
            });
        },
        qr/violates check constraint "build_completed_iff_started_check"/,
    );

    like(
        exception {
            $schema->resultset('build')->create({
                name => 'my first build',
                started => \'now()',
                completed => undef,
                completed_user_id => $user->id,
            });
        },
        qr/violates check constraint "build_completed_xnor_completed_user_id_check"/,
    );

    like(
        exception {
            $schema->resultset('build')->create({
                name => 'my first build',
                started => \'now()',
                completed => \'now()',
                completed_user_id => undef,
            });
        },
        qr/violates check constraint "build_completed_xnor_completed_user_id_check"/,
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
