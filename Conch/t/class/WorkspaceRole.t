use Mojo::Base -strict;
use Test::More;

use Conch::Class::WorkspaceRole;
use Data::Printer;

new_ok('Conch::Class::WorkspaceRole');

my $attrs = {
    id => 'id', name => 'name', role => 'role'
  };
my $ws_user = Conch::Class::WorkspaceRole->new({
    %$attrs, encode_json => sub { shift }
  });


can_ok($ws_user, 'id');
can_ok($ws_user, 'name');
can_ok($ws_user, 'description');
can_ok($ws_user, 'as_v1_json');

done_testing();

