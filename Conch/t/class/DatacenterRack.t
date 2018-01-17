use Mojo::Base -strict;
use Test::More;

use Conch::Class::DatacenterRack;
use Data::Printer;

new_ok('Conch::Class::DatacenterRack');

my %attrs = (
  id        => 'id',
  name      => 'name',
  role_name => 'role_name',
  datacenter_room_id => 'dc',
);

my $rack = Conch::Class::DatacenterRack->new(%attrs);

subtest "Method checks" => sub {
  can_ok($rack, 'id');
  can_ok($rack, 'name');
  can_ok($rack, 'role_name');
  can_ok($rack, 'datacenter_room_id');
  can_ok($rack, 'as_v1_json');
};

subtest "Naive value checks" => sub {
  is($rack->id,        $attrs{id});
  is($rack->name,      $attrs{name});
  is($rack->role_name, $attrs{role_name});
  is($rack->datacenter_room_id, $attrs{datacenter_room_id});
};

subtest "V1 Data Contract" => sub {
  diag("We never actually use as_v1_json in the codebase"); # TODO
  is_deeply($rack->as_v1_json, \%attrs);
};

done_testing();

