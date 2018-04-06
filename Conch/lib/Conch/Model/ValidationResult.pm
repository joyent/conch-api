=pod

=head1 NAME

Conch::Model::ValidationResult

=head1 METHODS

=cut

package Conch::Model::ValidationResult;
use Mojo::Base -base, -signatures;

use Digest::MD5 'md5_base64';

use constant {
	STATUS_ERROR => 'error',
	STATUS_FAIL  => 'fail',
	STATUS_PASS  => 'pass'
};

my $attrs = [
	qw(id device_id hardware_product_id validation_id message hint status
		category component_id result_order)
];
has $attrs;

=head2 TO_JSON

Render as a hashref for output

=cut

sub TO_JSON ($self) {
	return {
		id                  => $self->id,
		device_id           => $self->device_id,
		hardware_product_id => $self->hardware_product_id,
		validation_id       => $self->validation_id,
		message             => $self->message,
		hint                => $self->hint,
		status              => $self->status,
		category            => $self->category,
		component_id        => $self->component_id,
	};
}

=head2 new

Create a new Validation Result. Unlike other models, C<new> should be used and
then C<record> to write it to the database.

	my $result = Conch::Model::ValidationResult->new(
		device_id           => $device->id,
		validation_id       => $validation->id,
		hardware_product_id => $hardware_product_id,
		message             => 'Expected eq '1', got '2',
		category            => 'CPU',
		status              => 'fail',
		result_order        => 3
	);
	$result->record;

All unspecified attribute fields will be undef.

=cut

sub new ( $class, %args ) {
	$class->SUPER::new( %args{@$attrs} );
}

=head2 record

Record a new Validation Result. If the Validation result has already been
recorded (i.e. it has an ID), it will return the object unchanged. Recording is
write-once.

=cut

sub record ( $self ) {
	return $self if $self->id;

	my %record_attrs = %$self;
	delete $record_attrs{id};
	my $ret = Conch::Pg->new->db->insert( 'validation_result', {%record_attrs},
		{ returning => 'id' } )->hash;
	$self->id( $ret->{id} );

	return $self;
}

=head2 comparison_hash

Return an MD5 digest (base-64 encoded) of the attributes for comparing two
Validation Results to determine if they're contextually equivalent.

=cut

sub comparison_hash($self) {
	my @compared_attrs = qw( device_id hardware_product_id validation_id
		message status category component_id result_order);
	my @attr_values = grep { defined } @$self{@compared_attrs};

	# base64 encoding for serializability
	return md5_base64(@attr_values);
}

=head2 lookup

Lookup a validation result by ID or return undef

=cut

sub lookup ( $class, $id ) {
	my $ret =
		Conch::Pg->new->db->select( 'validation_result', $attrs, { id => $id } )
		->hash;
	return $class->new( $ret->%* ) if $ret;
}

=head2 grouped_by_validation_states

Given a list of ValidationState objects, group associated validation results.

Returns an array ref of hash refs with two keys. Key 'state' is a
ValidationState object, and key 'results' is an array ref of all
ValidationResult objects associated with the validation state.

=cut

sub grouped_by_validation_states ( $class, $validation_states ) {
	return [] unless scalar @$validation_states;

	my %groups =
		map { ( $_->id => { state => $_, results => [] } ) } $validation_states->@*;

	my @validation_state_ids = keys %groups;

	my $fields    = join( ', ', map { 'r.' . $_ } @$attrs );
	my $in_values = join( ', ', map { "'$_'" } @validation_state_ids );
	Conch::Pg->new->db->query(
		qq{
			select m.validation_state_id state_id, $fields
			from validation_result r
			join validation_state_member m
				on r.id = m.validation_result_id
			where m.validation_state_id in ($in_values)
			}
		)->hashes->map(
		sub {
			my %ret      = shift->%*;
			my $state_id = delete $ret{state_id};
			push @{ $groups{$state_id}->{results} }, $class->new(%ret);
			1;
		}
		);
	return [ values %groups ];
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
