use v5.26;
use warnings;
use Test::More;
use Test::Conch;
use Test::Fatal;

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
};


done_testing;
# vim: set ts=4 sts=4 sw=4 et :
