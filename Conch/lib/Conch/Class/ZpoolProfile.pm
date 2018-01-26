=pod

=head1 NAME

Conch::Class::ZpoolProfile

=head1 METHODS

=cut

package Conch::Class::ZpoolProfile;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';


=head2 cache

=head2 disk_per

=head2 log

=head2 name

=head2 spare

=head2 vdev_n

=head2 vdev_t

=cut

has [
	qw(
		name
		cache
		log
		disk_per
		spare
		vdev_n
		vdev_t
		)
];

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

