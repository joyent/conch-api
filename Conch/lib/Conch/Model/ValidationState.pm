=pod

=head1 NAME

Conch::Model::ValidationState

=head1 METHODS

=cut

package Conch::Model::ValidationState;
use Mojo::Base -base, -signatures;

my $attrs = [qw( id device_id validation_plan_id created completed )];
has $attrs;

=head2 create

Create a new validation state

=cut

sub create ( $class, $device_id, $validation_plan_id ) {
	my $ret = Conch::Pg->new->db->insert(
		'validation_state',
		{ device_id => $device_id, validation_plan_id => $validation_plan_id },
		{ returning => $attrs }
	)->hash;
	return $class->new( $ret->%* );
}

=head2 lookup

Lookup a validation state by ID or return undef

=cut

sub lookup ( $class, $id ) {
	my $ret =
		Conch::Pg->new->db->select( 'validation_state', undef, { id => $id } )
		->hash;
	return $ret && $class->new( $ret->%* );
}

=head2 mark_completed

Mark the Validation State as completed

=cut

sub mark_completed ( $self ) {
	my $completed = Conch::Pg->new->db->update(
		'validation_state',
		{ completed => 'NOW()' },
		{ id        => $self->id },
		{ returning => 'completed' }
	)->hash->{completed};
	$self->completed($completed);
	return $self;
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
