package Conch::Model::User;
use Mojo::Base -base, -signatures;

use Attempt qw(fail success);

use aliased 'Conch::Class::User';
use aliased 'Conch::Error::Conflict';

use Data::Printer;

has 'pg';
has 'hash_password';
has 'validate_against_hash';

sub create ( $self, $email, $password ) {
  my $password_hash = $self->hash_password->($password);

  $self->pg->db->select( 'user_account', ['id'], { email => $email } )->rows
    and return fail(
    Conflict->new( message => "User with email address already exists" ) );

  return success(
    User->new(
      $self->pg->db->insert(
        'user_account',
        {
          email         => $email,
          password_hash => $password_hash,
          name          => $email
        },
        { returning => [qw(id name email password_hash)] }
      )->hash
    )
  );
}

sub lookup ( $self, $user_id ) {
  my $user_res =
    $self->pg->db->select( 'user_account', undef, { id => $user_id } )->hash;
  return fail("No user with ID $user_id") unless $user_res;
  return success( User->new($user_res) );
}

sub update_password ( $self, $user_id, $password ) {
  my $password_hash = $self->hash_password->($password);
  $self->pg->db->update(
    'user_account',
    { password_hash => $password_hash },
    { id            => $user_id }
  )->rows;
}

sub lookup_by_email ( $self, $email ) {
  my $user_res =
    $self->pg->db->select( 'user_account', undef, { email => $email } )->hash;
  return fail('No user with email address') unless $user_res;
  return success( User->new($user_res) );
}

sub authenticate ( $self, $user_id, $password ) {
  my $user_res =
    $self->pg->db->select( 'user_account', undef, { name => $user_id } )->hash;

  unless ($user_res) {
    $user_res =
      $self->pg->db->select( 'user_account', undef, { email => $user_id } )
      ->hash;
  }

  return fail("No user with name or email address of  $user_id")
    unless $user_res;

  return success( User->new($user_res) )->next(
    sub {
      my $user          = shift;
      my $password_hash = $user->password_hash;
      $password_hash =~ s/{CRYPT}//;    # remove Dancer2 legacy prefix
      return fail('Invalid password attempt')
        unless $self->validate_against_hash->( $password, $password_hash );
      return $user;
    }
  );
}

1;
