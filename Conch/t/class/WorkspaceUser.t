use Mojo::Base -strict;
use Test::More;

use Mojo::Conch::Class::WorkspaceUser;
use Data::Printer;

new_ok('Mojo::Conch::Class::WorkspaceUser');

my $attrs = {
    id => 'id', name => 'name', role => 'role'
  };
my $ws_user = Mojo::Conch::Class::WorkspaceUser->new({
    %$attrs, encode_json => sub { shift }
  });


can_ok($ws_user, 'id');
can_ok($ws_user, 'name');
can_ok($ws_user, 'email');
can_ok($ws_user, 'role');
can_ok($ws_user, 'as_v2_json');

done_testing();
