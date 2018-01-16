package Conch::Class::WorkspaceRole;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [qw( id name description )];

1;

