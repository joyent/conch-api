package Mojo::Conch::Class::WorkspaceRole;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Mojo::Conch::Class::Role::JsonV2';

has [qw( id name description )];

1;


