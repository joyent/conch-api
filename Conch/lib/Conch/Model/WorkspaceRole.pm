package Conch::Model::WorkspaceRole;
use Mojo::Base -base, -signatures;

use aliased 'Conch::Class::WorkspaceRole';

has 'pg';

sub list ( $self ) {
  $self->pg->db->select( 'role', undef )
    ->hashes->map( sub { WorkspaceRole->new(shift) } )->to_array;
}

sub lookup_by_name ( $self, $role_name ) {
  my $ret = $self->pg->db->select(
    'role',
    undef,
    { name => $role_name }
  )->hash;
  return undef unless $ret;
  return WorkspaceRole->new($ret);
}

1;
