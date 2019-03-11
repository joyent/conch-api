use v5.26;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Conch;

my $t = Test::Conch->new;
my $global_ws_id = $t->load_fixture('conch_user_global_workspace')->workspace_id;

$t->authenticate;

subtest 'Workspace Rooms' => sub {
    $t->get_ok('/workspace/'.$global_ws_id.'/room')
        ->status_is(410);

    $t->put_ok('/workspace/'.$global_ws_id.'/room', json => [0, 1])
        ->status_is(410);
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
