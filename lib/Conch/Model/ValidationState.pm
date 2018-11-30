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

my $attrs = [qw( id device_id validation_plan_id status created completed device_report_id)];
has $attrs;

=head2 TO_JSON

=cut

sub TO_JSON ($self) {
	{
		id                 => $self->id,
		device_id          => $self->device_id,
		validation_plan_id => $self->validation_plan_id,
		status             => $self->status,
		created            => Conch::Time->new( $self->created ),
		completed => $self->completed && Conch::Time->new( $self->completed ),
		device_report_id   => $self->device_report_id,
	};
}

=head2 create

Create a new validation state

=cut

sub create ( $class, $device_id, $device_report_id, $validation_plan_id ) {
	my $ret = Conch::Pg->new->db->insert(
		'validation_state',
		{ device_id => $device_id, device_report_id => $device_report_id, validation_plan_id => $validation_plan_id },
		{ returning => $attrs }
	)->hash;
	return $class->new( $ret->%* );
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

=head2 update

	$state->update(\@new_results);

Update the database with the new validation results. If the current object has
already been recorded, a new ValidationState object will be created and
returned. 

The methodology here is a little bendy. If an earlier state recorded the same
result as one provided, the new state will point to that old result, thus
preventing extraneous data in the database. If there is no earlier state or none
matching our results, the results will be added to the database.

=cut

sub update ($self, $new_results = []) {
	my %latest_results = map { ( $_->comparison_hash => $_ ) } 
			$self->validation_results->@*;

	my $state = $self;
	die 'validation_state not yet created in the db' if not $state->status;

	my @results;

	my %status;
	for my $result (@$new_results) {
		if ( my $last_result = $latest_results{ $result->comparison_hash } ) {
			$state->add_validation_result( $last_result->id );
			$status{ $last_result->status } = 1;
		} else {
			$state->add_validation_result( $result->record() );
			$status{ $result->status } = 1;
		}
	}

	my $state_status;
	if($status{STATUS_ERROR()}) {
		$state_status = STATUS_ERROR;

	} elsif($status{STATUS_FAIL()}) {
		$state_status = STATUS_FAIL;

	} else {
		$state_status = STATUS_PASS;
	}

	$state->mark_completed($state_status);
	return $state;
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
