package Mojo::Conch::Model::WorkspaceRole;
use Mojo::Base -base, -signatures;

use Attempt 'when_defined';
use aliased 'Mojo::Conch::Class::WorkspaceRole';

has 'pg';

sub list ( $self ) {
  $self->pg->db->select( 'role', undef )
    ->hashes->map( sub { WorkspaceRole->new(shift) } )->to_array;
}

sub lookup_by_name ( $self, $role_name ) {
  when_defined { WorkspaceRole->new(shift) }
  $self->pg->db->select( 'role', undef, { name => $role_name } )->hash;
}

1;
