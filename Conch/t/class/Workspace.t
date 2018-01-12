use Mojo::Base -strict;
use Test::More;

use Conch::Class::Workspace;
use Data::Printer;

new_ok('Conch::Class::Workspace');

my $attrs = {
    id => 'id', name => 'name', description => 'description',
    parent_workspace_id => 'parent_workspace_id'
  };
my $ws = Conch::Class::Workspace->new({
    %$attrs, encode_json => sub { shift }
  });


can_ok($ws, 'id');
can_ok($ws, 'name');
can_ok($ws, 'description');
can_ok($ws, 'parent_workspace_id');
can_ok($ws, 'role');
can_ok($ws, 'role_id');
can_ok($ws, 'as_v2_json');
is($ws->as_v2_json->{parent_workspace_id}, undef, 'parent workspace ID not published');

done_testing();
