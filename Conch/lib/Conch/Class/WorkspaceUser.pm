package Conch::Class::WorkspaceUser;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [qw( id name email role )];

1;

