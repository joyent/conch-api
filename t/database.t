use v5.26;
use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Conch;
use Test::Fatal;
use Test::Warnings ':all';
use Test::Memory::Cycle;
use Test::Deep;
use Data::UUID;

subtest 'db connection without Conch, legacy mode, and data preservation' => sub {
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

    cmp_deeply(
        [ Test::Conch->new(legacy_db => 1)->app->db_user_accounts->get_column('name')->all ],
        [ Test::Conch->CONCH_USER ],
        'Conch app with legacy db gets a database instance with the conch user',
    );

    is(
        Test::Conch->new(legacy_db => 0)->app->db_user_accounts->count,
        0,
        'Conch app with no legacy db gets a new database instance with no users',
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

    # clear the transaction, because we have AutoCommit => 0 for this connection.
    # (as an alternative, we can turn the ReadOnly flag off, and use the read-only
    # credentials to connect to the server.. but it is better to have this safety here.)
    $t->app->ro_schema->txn_rollback;

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


    is(
        $t->app->txn_wrapper(sub ($self, @args) {
            cmp_deeply(\@args, [ 'hello', 'there' ], 'got the extra argument(s)');

            $t->app->db_user_accounts->create({
                name => 'another new user',
                email => 'test2@conch.joyent.us',
                password => 'whargarbl',
            });
            is($t->app->db_user_accounts->count, $user_count + 1, 'another user was created');
            die 'rollback';

        }, 'hello', 'there'),
        undef,
        'return value is undef in case of an exception',
    );

    is($t->app->db_user_accounts->count, $user_count, 'the new user was rolled back (again)');


    $t->app->routes->get(
        '/test_txn_wrapper',
        sub ($c) {
            $c->txn_wrapper(sub ($my_c, $id) {
                $my_c->db_user_accounts->create({
                    id => $id,
                    name => 'new user',
                    email => 'foo@bar',
                    password => 'foo',
                });
                $my_c->status(200);
            }, $c->req->query_params->param('id'));
        },
    );

    $t->get_ok('/test_txn_wrapper?id=bad_id')
        ->status_is(400)
        ->json_cmp_deeply('', { error => re(qr/invalid input syntax for (?:type )?uuid: "bad_id"/) });

    is($t->app->db_user_accounts->count, $user_count, 'no new user was created');

    $t->get_ok('/test_txn_wrapper?id=' . Data::UUID->new->create_str)
        ->status_is(200);

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
    my $new_user_copy = $t2->app->db_user_accounts->find({ name => 'foo' });
    is($new_user->id, $new_user_copy->id, 'can obtain the user from the second test instance');
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
