package Mojo::Conch::Class::Workspace;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Mojo::Conch::Class::Role::JsonV2';

has [qw( id name description parent_workspace_id role role_id )];

sub as_v2_json {
  my $self = shift;
  {
    id => $self->id,
    name => $self->name,
    description => $self->description,
    role => $self->role
  }
}

1;

