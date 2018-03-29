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
		Conch::Pg->new->db->select( 'validation_state', $attrs, { id => $id } )
		->hash;
	return $class->new( $ret->%* ) if $ret;
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

=head2 latest_completed_state

Find the latest completed validation state for a given Device and Validation
Plan, or return undef

=cut

sub latest_completed_state ( $class, $device_id, $plan_id ) {
	my $fields = join( ', ', @$attrs );
	my $ret = Conch::Pg->new->db->query(
		qq{
		select $fields
		from validation_state
		where
			device_id = ? and
			validation_plan_id = ? and
			completed is not null
		order by completed desc
		limit 1
		},
		$device_id, $plan_id
	)->hash;
	return $class->new( $ret->%* ) if $ret;
}

=head2 add_validation_result

Assoicate a validation result with the validation state. Returns the validation
state. Idempotent and will only ever add once.

=cut

sub add_validation_result ( $self, $validation_result ) {
	my $validation_result_id =
		  $validation_result->isa('Conch::Model::ValidationResult')
		? $validation_result->id
		: $validation_result;
	Conch::Pg->new->db->query(
		q{
		insert into validation_state_member
			(validation_state_id, validation_result_id)
			values (?, ?)
		on conflict (validation_state_id, validation_result_id)
			do nothing
		}, $self->id, $validation_result_id
	);

	return $self;
}

=head2 validation_results

Return an array of associated validation results associated with the validation
state.

=cut

sub validation_results ($self) {
	Conch::Pg->new->db->query(
		q{
		select result.*
		from validation_result result
		join validation_state_member member
			on member.validation_result_id = result.id
		where member.validation_state_id = ?
		},
		$self->id
		)->hashes->map( sub { Conch::Model::ValidationResult->new( shift->%* ) } )
		->to_array;
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
