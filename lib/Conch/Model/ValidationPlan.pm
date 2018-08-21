=pod

=head1 NAME

Conch::Model::ValidationPlan

=head1 METHODS

=cut

package Conch::Model::ValidationPlan;
use Mojo::Base -base, -signatures;
use Conch::Pg;

my $attrs = [qw( id name description created )];
has $attrs;

use Conch::Log;
has 'log' => sub { return Conch::Log->new() };

=head2 TO_JSON

Render as a hashref for output

=cut

sub TO_JSON ($self) {
	{
		id          => $self->id,
		name        => $self->name,
		description => $self->description,
		created     => Conch::Time->new( $self->created )
	};
}

=head2 create

Create a new validation plan

=cut

sub create ( $class, $name, $description ) {
	my $ret = Conch::Pg->new->db->insert(
		'validation_plan',
		{ name      => $name, description => $description },
		{ returning => $attrs }
	)->hash;
	return $class->new( $ret->%* );
}

=head2 lookup

Lookup a validation plan by ID

=cut

sub lookup ( $class, $id ) {
	my $ret =
		Conch::Pg->new->db->select( 'validation_plan', $attrs, { id => $id } )
		->hash;
	return $ret && $class->new( $ret->%* );
}

=head2 lookup_by_name

Lookup a validation plan by name. Name is unique for validation plans.

=cut

sub lookup_by_name ( $class, $name ) {
	my $ret =
		Conch::Pg->new->db->select( 'validation_plan', $attrs, { name => $name } )
		->hash;
	return $ret && $class->new( $ret->%* );
}

=head2 list

List all active Validation Planss

=cut

sub list ( $class ) {
	Conch::Pg->new->db->select( 'validation_plan', $attrs,
		{ deactivated => undef } )->hashes->map( sub { $class->new( shift->%* ) } )
		->to_array;
}

=head2 validation_ids

Get a array of validation IDs associated with a validation plan

=cut

sub validation_ids ( $self ) {
	return Conch::Pg->new->db->select( 'validation_plan_member',
		['validation_id'], { validation_plan_id => $self->id } )
		->arrays->map( sub { $_->[0] } )->to_array;
}

=head2 validations

Get a array of C<Conch::Model::Validation>s associated with a validation plan

=cut

sub validations ( $self ) {
	return Conch::Pg->new->db->query(
		qq{
		SELECT v.*
		FROM validation v
		JOIN validation_plan_member vpm
			ON v.id = vpm.validation_id
		WHERE
			vpm.validation_plan_id = ?
		}, $self->id
		)->hashes->map( sub { Conch::Model::Validation->new( shift->%* ) } )
		->to_array;
}

=head2 add_validation

Associate a validation with this validation plan. Can pass either a validation
ID string or a C<Conch::Model::Validation> object. Returns the object.

=cut

sub add_validation ( $self, $validation ) {
	my $validation_id =
		  $validation->isa('Conch::Model::Validation')
		? $validation->id
		: $validation;
	Conch::Pg->new->db->query(
		q{
		INSERT INTO validation_plan_member (validation_id, validation_plan_id)
			VALUES (?, ?)
		ON CONFLICT (validation_id, validation_plan_id) DO NOTHING
		}, $validation_id, $self->id
	);

	return $self;
}

=head2 drop_validations

Remove all associations of validation with this validation plan.  Returns the
object.

B<Note>: This removes the join-table associations between the C<validation_plan>
and C<validation> tables. It does not use a C<deactivated> flag.

=cut

sub drop_validations ( $self ) {
	Conch::Pg->new->db->delete( 'validation_plan_member',
		{ validation_plan_id => $self->id } );

	return $self;
}

=head2 remove_validation

Remove the association of validation with this validation plan. Can pass either
a validation ID string or a C<Conch::Model::Validation> object. Returns the
object.

B<Note>: This removes the join-table association between the C<validation_plan>
and C<validation> tables. It does not use a C<deactivated> flag.

=cut

sub remove_validation ( $self, $validation ) {
	my $validation_id =
		  $validation->isa('Conch::Model::Validation')
		? $validation->id
		: $validation;
	Conch::Pg->new->db->delete( 'validation_plan_member',
		{ validation_id => $validation_id, validation_plan_id => $self->id } );

	return $self;
}

=head2 run_validations

Run all Validations in the Validation Plan with the given device and input
data. Returns the list of validation results.

=cut

sub run_validations ( $self, $device, $data ) {
	my $location = Conch::Model::DeviceLocation->lookup( $device->id );

	# see Conch::DB::ResultSet::DeviceSetting::get_settings
	my $settings = Conch::Pg->new->db->select( 'device_settings', undef,
		{ deactivated => undef, device_id => $device->id } )
		->expand->hashes
		->reduce(
			sub {
				$a->{ $b->{name} } = $b->{value};
				$a;
			},
			{}
		);

	my $hw_product_id =
		  $location
		? $location->target_hardware_product->id
		: $device->hardware_product_id;
	my $hw_product = Conch::Model::HardwareProduct->lookup($hw_product_id);

	my @results;
	for my $validation ( $self->validations->@* ) {
		my $validator = $validation->build_device_validation(
			$device,
			$hw_product,
			$location,
			$settings
		);
		$validator->log($self->log);

		$validator->run($data);
		push @results, $validator->validation_results->@*;
	}
	return \@results;
}

=head2 run_with_state

Process a validation plan with a device ID and input data. Returns a completed
validation state. Associated validation results will be stored.

=cut

# FIXME we need the device id here because this code is called from places
# where the "device" is dbic and thus way more helpful than our usual Model.
# Specifically, it resolves ids to the real object, throwing later code for a
# fit
sub run_with_state($self, $device_id, $data) {
    Mojo::Exception->throw("Device ID must be defined") unless $device_id;
    Mojo::Exception->throw("Validation data must be a hashref")
        unless ref($data) eq 'HASH';

	my $device = Conch::Model::Device->lookup($device_id);
	Mojo::Exception->throw("No device exists with ID $device_id") unless $device;

	my $state = Conch::Model::ValidationState->latest_completed_for_device_plan(
		$device->id,
		$self->id
	);

	my $new_results = $self->run_validations( $device, $data );

	unless($state) {
		$state = Conch::Model::ValidationState->create(
			$device->id,
			$self->id
		);
	}

	return $state->update($new_results);

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
