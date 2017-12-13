package Mojo::Conch::Class::User;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Mojo::Conch::Class::Role::JsonV2';

has [qw( id name email password_hash )];

1;
