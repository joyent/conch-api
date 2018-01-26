=pod

=head1 NAME

Conch::Class::WorkspaceUser

=head1 METHODS

=cut

package Conch::Class::WorkspaceUser;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';


=head2 id

=head2 name

=head2 email

=head2 role

=cut

has [qw( id name email role )];

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

