use Mojo::Base -strict;
use Test::More;

use Conch::Class::DatacenterRoom;
use Data::Printer;

new_ok('Conch::Class::DatacenterRoom');

my $attrs = {
    id => 'id', az => 'az', alias => 'alias', vendor_name => 'vendor_name'
  };
my $ws_user = Conch::Class::DatacenterRoom->new({
    %$attrs, encode_json => sub { shift }
  });


can_ok($ws_user, 'id');
can_ok($ws_user, 'az');
can_ok($ws_user, 'alias');
can_ok($ws_user, 'vendor_name');
can_ok($ws_user, 'as_v1_json');

done_testing();

