use Mojo::Base -strict;
use Test::More;

use Mojo::Conch::Class::DatacenterRack;
use Data::Printer;

new_ok('Mojo::Conch::Class::DatacenterRack');

my $attrs = {
    id => 'id', name => 'name', role_name => 'name'
  };
my $ws_user = Mojo::Conch::Class::DatacenterRack->new({
    %$attrs, encode_json => sub { shift }
  });


can_ok($ws_user, 'id');
can_ok($ws_user, 'name');
can_ok($ws_user, 'role_name');
can_ok($ws_user, 'as_v2_json');

done_testing();

