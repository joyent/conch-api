=pod

=head1 NAME

Conch::Model::Device

=head1 METHODS

=cut
package Conch::Model::Device;
use Role::Tiny 'with';
use Mojo::Base -base, -signatures;

use Conch::Time;
use Conch::UUID qw(is_uuid);

has [
	qw(
		asset_tag
		created
		graduated
		hardware_product_id
		health
		hostname
		id
		last_seen
		latest_triton_reboot
		state
		system_uuid
		triton_setup
		triton_uuid
		updated
		uptime_since
		validated
		)
];

=head2 new

=cut
sub new ( $class, %args ) {
	map { $args{$_} = Conch::Time->new( $args{$_} ) if $args{$_} }
		qw(created graduated last_seen latest_triton_reboot triton_setup updated uptime_since validated);
	$class->SUPER::new(%args);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
