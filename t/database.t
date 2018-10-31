use v5.26;
use warnings;
use Test::More;
use Test::Conch;
use Test::Fatal;
use Test::Warnings ':all';
use Test::Memory::Cycle;

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
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
