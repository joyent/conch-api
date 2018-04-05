=pod

=head1 NAME

Conch::Model::ValidationState

=head1 METHODS

=cut

package Conch::Model::ValidationState;
use Mojo::Base -base, -signatures;

use constant {
	STATUS_ERROR => 'error',
	STATUS_FAIL  => 'fail',
	STATUS_PASS  => 'pass'
};

my $attrs = [qw( id device_id validation_plan_id status created completed )];
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

Mark the Validation State as completed with a status

=cut

sub mark_completed ( $self, $status ) {
	my $state = Conch::Pg->new->db->update(
		'validation_state',
		{ completed => 'NOW()', status => $status },
		{ id        => $self->id },
		{ returning => [ 'completed', 'status' ] }
	)->hash;
	$self->completed( $state->{completed} );
	$self->status( $state->{status} );
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

=head2 run_validation_plan

Process a validation plan with a device and input data. Returns a completed
validation state. Associated validation results will be stored.

=cut

sub run_validation_plan ( $class, $device_id, $validation_plan_id, $data ) {

	Mojo::Exception->throw("Device ID must be defined") unless $device_id;
	Mojo::Exception->throw("Validation Plan ID must be defined")
		unless $validation_plan_id;
	Mojo::Exception->throw("Validation data must be a hashref")
		unless ref($data) eq 'HASH';

	my $device = Conch::Model::Device->lookup($device_id);

	Mojo::Exception->throw("No device exists with ID '$device_id'")
		unless $device;

	my $validation_plan =
		Conch::Model::ValidationPlan->lookup($validation_plan_id);
	Mojo::Exception->throw(
		"No Validation Plan found with ID '$validation_plan_id'")
		unless $validation_plan;

	my $validation_state = $class->create( $device_id, $validation_plan->id );

	my $latest_state =
		$class->latest_completed_state( $device_id, $validation_plan_id );

	my %latest_results =
		map { ( $_->comparison_hash => $_ ) } $latest_state->validation_results->@*
		if $latest_state;

	my $new_results = $validation_plan->run_validations( $device, $data );

	my %status = ();

	# For all new results, check to see if a contextually equivalent result
	# that occurred with the previous state. If the older result is the same as
	# the new result, associate the new state with the older result and do not
	# store the new result. This reduces the number of redundant results stored
	# in the database.
	for my $result (@$new_results) {
		if ( my $last_result = $latest_results{ $result->comparison_hash } ) {
			$validation_state->add_validation_result( $last_result->id );
			$status{ $last_result->status } = 1;
		}
		else {
			$validation_state->add_validation_result( $result->record() );
			$status{ $result->status } = 1;
		}
	}

	# if any result status was ERROR, the state status is ERROR. Else, if any
	# were FAIL, the state status is FAIL. Otherwise, the state status is
	# PASS
	my $state_status =
		  $status{ STATUS_ERROR() } ? STATUS_ERROR
		: $status{ STATUS_FAIL() }  ? STATUS_FAIL
		:                             STATUS_PASS;

	$validation_state->mark_completed($state_status);

	return $validation_state;
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
