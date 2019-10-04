use v5.26;
use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Conch;
use Test::Fatal;
use Test::Warnings ':all';
use Test::Memory::Cycle;
use Test::Deep;
use Data::UUID;
use Conch::DB::Util;

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
        exception {
            $t->app->db_ro_user_accounts->create({
                name => 'another new user',
                email => 'test2@conch.joyent.us',
                password => 'whargarbl',
            });
        },
        qr/cannot execute INSERT in a read-only transaction/,
        'cannot create a user using the read-only db handle',
    );

    is(
        exception {
            $t->app->db_ro_user_accounts->find($user1->id);
        },
        undef,
        'no exception querying for a user using the read-only db handle',
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
        '/test_txn_wrapper1',
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
        '/test_txn_wrapper2',
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

    $t->get_ok('/test_txn_wrapper1')
        ->content_is('', 'no error response was prepared on intentional rollback');

    is($t->app->db_user_accounts->count, $user_count, 'the new user was rolled back (again)');


    $t->get_ok('/test_txn_wrapper2?id=bad_id')
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/invalid input syntax for (?:type )?uuid: "bad_id"/) });

    is($t->app->db_user_accounts->count, $user_count, 'no new user was created');

    $t->get_ok('/test_txn_wrapper2?id='.Data::UUID->new->create_str)
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

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
