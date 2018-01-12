use Mojo::Base -strict;
use Test::More;

use Conch::Class::User;
use Data::Printer;

new_ok('Conch::Class::User');

my $attrs = {
    id => 'id', name => 'name', password_hash => 'hash'
  };
my $user = Conch::Class::User->new({
    %$attrs, encode_json => sub { shift }
  });


can_ok($user, 'id');
can_ok($user, 'name');
can_ok($user, 'password_hash');

can_ok($user, 'as_v2_json');

done_testing();
