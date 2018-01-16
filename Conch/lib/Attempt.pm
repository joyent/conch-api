package Attempt;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(fail success try sequence attempt when_defined);

sub fail {
  return bless { value => $_[0] }, __PACKAGE__ . '::Fail';
}

sub success {
  return bless { value => $_[0] }, __PACKAGE__ . '::Success';
}

sub try (&) {
  my $sub = shift;
  my $res;
  eval { $res = $sub->(); };
  return fail($@) if $@;
  return success($res);
}

sub attempt ($) {
  my $value = shift;
  if ( defined $value ) {
    return success($value);
  }
  else {
    return fail();
  }
}

sub when_defined (&$) {
  my $sub   = shift;
  my $value = shift;
  if ( defined $value ) {
    return success($value)->next($sub);
  }
  else {
    return fail();
  }
}

sub sequence {
  my $acc = success( [] );
  my $foo = @_;
  for (@_) {
    if ( $_->is_success ) {
      $acc = $acc->next(
        sub {
          my $values = shift;
          push @$values, $_->value;
          return $values;
        }
      );
    }
    else {
      $acc = $_;
      last;
    }
  }
  return $acc;
}

sub is_fail {
  return !shift;
}

sub is_success {
  return !!shift;
}

sub value {
  my $self = shift;
  return $self->is_success ? $self->{value} : undef;
}

sub failure {
  my $self = shift;
  return $self->is_fail ? $self->{value} : undef;
}

sub next {
  my ( $self, $f ) = @_;
  return $self if $self->is_fail;

  my $next = $f->( $self->value );
  my $pkg  = __PACKAGE__;

  # $next is either Success or Fail
  return $next if ref($next) =~ /^$pkg/;

  # Wrap up non-attempt values in Success
  return success($next);
}

package Attempt::Fail;
use parent -norequire, 'Attempt';
use overload 'bool' => sub { 0 };

package Attempt::Success;
use parent -norequire, 'Attempt';
use overload 'bool' => sub { 1 };

1;

__END__

=head1 NAME

Attempt -- There is no try


=head1 DESCRIPTION

Attempt allows you to try a process that may fail, but continue programming as
if it all succeeded. If there's any failure along the way, the result is a
C<Attempt::Fail>. Otherwise, it's a C<Attempt::Success>.

C<Attempt::Success> and C<Attempt::Success> are I<immutable>. Methods will
return values or new objects rather than modifying the object.

=head1 FUNCTIONS

=head2 Attempt::success($ref)

Mark a value as successful.

=head2 Attempt::fail($ref)

Mark a value as a failure.

=head2 Attempt::sequence($attempt1, $attempt2, ...)

Sequence a list of Attempts in order. Returns a Attempt::Success with an array
ref of all values if every Attempt is Attempt::Success. Otherwise, it will
return the I<first> Attempt::Fail. 

=head2 Attempt::try { block };

Try-catch mechanism. Evaluate a block of code and return a Attempt::Success
with the returned value or a Attempt::Fail containing the first exception
thrown in the execution of the block.

=head2 Attempt::attempt($ref);

Used to handle values that could be undefined. Returns Attempt::Success
containing the value if $ref is defined, Attempt::Fail otherwise.

=head2 Attempt::when_defined { sub } $ref;

Used to modify values that could be undefined. Returns Attempt::Success
containing the value modified by the subroutine if $ref is defined,
Attempt::Fail otherwise.

=head1 METHODS

=head2 $attempt->is_success()

Determine whether an attempt was a success.

=head2 $attempt->is_fail()

Determine whether an attempt was a failure.

=head2 $attempt->next(&sub)

Apply a subroutine to the value contained by $attempt B<if and only if> the
$attempt is a success.

If $attempt a failure, the function will not be applied and $attempt will
remain unchanged.

The subroutine can either return a new value to be stored in succesful attempt,
or a new C<Attempt> object. This second option is powerful because it allows
you to chain multiple processes together, any which might fail. This allows you
not to worry or check whether you're passing a failure value 'downstream',
because only successful values will be propogated through C<next>.

=head2 $attempt->value()

Retrieve the value contained by a successful attempt or C<undef> if it was a
failure. Using explicit checks with C<is_success> or the boolean overloading
is recommended.

=head2 $attempt->failure()

Retrieve the value contained by a failed attempt or C<undef> if it was
successful.

=head1 EXAMPLE

  sub random_failure {
    my $bound = shift;
    my $rand = rand($bound);
    if ($rand > ($bound / 2) ) {
      return Attempt->success($rand)
    }
    else {
      return Attempt->fail($rand);
    }
  }

  my $attempt =
    random_failure(10)
      ->next( sub { 10 * shift } )
      ->next( sub { random_failure(shift) } )
      ->next( sub { "Final successful value is: " . shift });


C<$attempt> will start out either as a C<Attempt::Success> or an
C<Attempt::Fail> based on the result of the first C<random_failure> call. If it
returns a C<Attempt::Success>, the random number will be multiplied by 10.
If it returns C<Attempt::Fail>, no further processing will occur.
C<random_failure> is invoked again with the new value multipled by 10. Once
again, if successful, the process with continue; otherwise, it will keep its
failure value. Finally, the value will be concatenated to a string if
