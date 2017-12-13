use strict;

use Test::More;
use Attempt 'sequence';

use Data::Printer;


subtest "Attempt::fail" => sub {
  my $scalar_fail = Attempt::fail('fail');
  isa_ok($scalar_fail, 'Attempt::Fail');
  ok($scalar_fail->is_fail, 'is fail');
  ok(!$scalar_fail, 'is falsey');
  is($scalar_fail->value, undef, '->value is undef');
  is($scalar_fail->failure, 'fail', 'Fail has assigned scalar value');

  my $hash = {foo => 'bar', baz => 'gaz' };
  my $hash_fail = Attempt::fail($hash);
  is_deeply($hash_fail->failure, $hash, 'Fail has assigned hash value');

  my $array = [1, 2, 3];
  my $array_fail = Attempt::fail($array);
  is_deeply($array_fail->failure, $array, 'Fail has assigned array value');
};

subtest "Attempt::success" => sub {
  my $scalar_success = Attempt::success('success');
  isa_ok($scalar_success, 'Attempt::Success');
  ok($scalar_success->is_success, 'is success');
  ok(!!$scalar_success, 'is truthy');
  is($scalar_success->failure, undef, '->failure is undef');
  is($scalar_success->value, 'success', 'Success has assigned scalar value');

  ok($scalar_success, "Success is boolean true");

  my $hash = {foo => 'bar', baz => 'gaz' };
  my $hash_success = Attempt::success($hash);
  is_deeply($hash_success->value, $hash, 'Success has assigned hash value');

  my $array = [1, 2, 3];
  my $array_success = Attempt::success($array);
  is_deeply($array_success->value, $array, 'Success has assigned array value');
};

subtest "Next on an Attempt" => sub {
  my $success = Attempt::success(2);
  my $next = $success->next(sub { 3 + shift });

  is($success->value, 2, 'Original success has same value');

  isa_ok($next, 'Attempt::Success');
  is($next->value, 5, 'Next has calculated value' );

  my $next_success = $success->next(sub { return Attempt::success(8 + shift) });
  isa_ok($next_success, 'Attempt::Success');
  is($next_success->value, 10, '->next returning a Success is flattened' );

  my $next_fail = $success->next(sub { return Attempt::fail(-1 * shift) });
  isa_ok($next_fail, 'Attempt::Fail');
  is($next_fail->failure, -2, '->next returning Fail is flattened' );
};

subtest "Sequencing Attempts" => sub {
  my $success1 = Attempt::success(1);
  my $success2 = Attempt::success(2);
  my $success3 = Attempt::success(3);

  my $seq_success = sequence($success1, $success2, $success3);
  isa_ok($seq_success, 'Attempt::Success');
  is_deeply($seq_success->value, [1,2,3], "Contains successful values");

  my $fail = Attempt::fail(-1);
  my $seq_fail_first = sequence($fail, $success1, $success2);
  isa_ok($seq_fail_first, 'Attempt::Fail');
  is($seq_fail_first->failure, -1,  'First failure value');

  my $seq_fail_last = sequence($success1, $success2, $fail);
  isa_ok($seq_fail_last, 'Attempt::Fail');
  is($seq_fail_last->failure, -1,  'First failure value');

};

subtest 'Catching exceptions' => sub {
  my $no_exception = Attempt::try { return 1; };
  isa_ok($no_exception, 'Attempt::Success');
  is($no_exception->value, 1, 'Contains return value');

  my $fail_exception = Attempt::try { die 'boom'; };
  isa_ok($fail_exception, 'Attempt::Fail');
  like($fail_exception->failure, qr/^boom/, 'Contains exception value');

};

subtest 'attempt' => sub {
  can_ok('Attempt', 'attempt');
  my $defined = Attempt::attempt 1;
  isa_ok($defined , 'Attempt::Success');
  is($defined->value, 1, 'Contains value');

  my $not_defined = Attempt::attempt undef;
  isa_ok($not_defined , 'Attempt::Fail');
  is($defined->failure, undef, 'Contains undef failure value');
};

subtest 'when defined' => sub {
  can_ok('Attempt', 'when_defined');
  my $defined = Attempt::when_defined { 2 + shift } 1;
  isa_ok($defined , 'Attempt::Success');
  is($defined->value, 3, 'Contains modified value');

  my $not_defined = Attempt::when_defined { 2 + shift } undef;
  isa_ok($not_defined , 'Attempt::Fail');
  is($defined->failure, undef, 'Contains undef failure value');
};

done_testing();
