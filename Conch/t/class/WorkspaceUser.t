use Mojo::Base -strict;
use Test::More;

use Conch::Class::WorkspaceUser;
use Data::Printer;

new_ok('Conch::Class::WorkspaceUser');

my $attrs = {
    id => 'id', name => 'name', role => 'role'
  };
my $ws_user = Conch::Class::WorkspaceUser->new({
    %$attrs, encode_json => sub { shift }
  });


can_ok($ws_user, 'id');
can_ok($ws_user, 'name');
can_ok($ws_user, 'email');
can_ok($ws_user, 'role');
can_ok($ws_user, 'as_v1_json');

fail("Test more than the existence of methods");

done_testing();
