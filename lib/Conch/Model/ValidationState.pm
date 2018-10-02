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

=head2 lookup

Lookup a validation state by ID or return undef

=cut

sub lookup ( $class, $id ) {
	my $ret =
		Conch::Pg->new->db->select( 'validation_state', $attrs, { id => $id } )
		->hash;
	return $class->new( $ret->%* ) if $ret;
}

=head2 lookup_with_device

Lookup a validation state by ID and Device ID or return undef

=cut

sub lookup_with_device ( $class, $id, $device_id ) {
	my $ret =
		Conch::Pg->new->db->select( 'validation_state', $attrs,
		{ id => $id, device_id => $id } )->hash;
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

=head2 latest_for_device_plan

Find the latest validation state for a given Device and Validation
Plan, or return undef

=cut

sub latest_for_device_plan ( $class, $device_id, $plan_id ) {
	my $fields = join( ', ', @$attrs );
	my $ret = Conch::Pg->new->db->query(
		qq{
		select $fields
		from validation_state
		where
			device_id = ? and
			validation_plan_id = ?
		order by created desc
		limit 1
		},
		$device_id, $plan_id
	)->hash;
	return $class->new( $ret->%* ) if $ret;
}

=head2 latest_completed_grouped_states_for_device

Return all latest completed states for a device, grouped with the
results of each state.

=cut

sub latest_completed_grouped_states_for_device ( $class, $device_id, @statuses )
{
	my $state_fields = join( ', ', map { "state.$_ as state_$_" } @$attrs );
	my $result_fields = join( ', ',
		map { "result.$_ as result_$_" } @$Conch::Model::ValidationResult::attrs );

	my $status_condition = @statuses ? "and status = any(?)" : "";

	my %groups;

	return $class->_group_results_by_validation_state(
		Conch::Pg->new->db->query(
			qq{
				select $state_fields, $result_fields
				from validation_result result
				join validation_state_member m
					on m.validation_result_id = result.id
				join (
					select distinct on (vs.validation_plan_id) vs.*
					from validation_state vs
					where
						vs.completed is not null
						and vs.device_id = ?
						$status_condition
					order by
						vs.validation_plan_id,
						vs.completed desc
				) state
					on state.id = m.validation_state_id
			}, ( $device_id, @statuses ? \@statuses : () )
		)->hashes
	);
}

sub _group_results_by_validation_state ( $class, $hashes ) {
	my %groups;
	$hashes->map(
		sub {
			my %ret = shift->%*;
			my %state_values;
			my %result_values;
			while ( my ( $k, $v ) = each %ret ) {
				if ( $k =~ s/^state_// ) {
					$state_values{$k} = $v;
				}
				elsif ( $k =~ s/^result_// ) {
					$result_values{$k} = $v;
				}
			}
			my $state_id = $state_values{id};
			unless ( defined $groups{$state_id} ) {
				$groups{$state_id}->{state} = $class->new(%state_values);
			}
			push @{ $groups{$state_id}->{results} },
				Conch::Model::ValidationResult->new(%result_values);
			1;
		}
	);
	return [ sort { $b->{state}->completed cmp $a->{state}->completed }
			values %groups ];
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
