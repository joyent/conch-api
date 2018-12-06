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

has 'log' => sub { Carp::croak('missing logger') };

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

=head2 run_validations

Run all Validations in the Validation Plan with the given device and input
data. Returns the list of validation results.

=cut

sub run_validations ( $self, $device, $data ) {
	my $location = Conch::Model::DeviceLocation->lookup( $device->id );

	# see Conch::DB::ResultSet::DeviceSetting::get_settings
	my $settings = Conch::Pg->new->db->select( 'device_setting', undef,
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

		$validation->log($self->log);
		my $validator = $validation->build_device_validation(
			$device,
			$hw_product,
			$location,
			$settings
		);

		$validator->run($data);
		push @results, $validator->validation_results->@*;
	}
	return \@results;
}

=head2 run_with_state

Process a validation plan with a device and input data. Returns a completed
validation state. Associated validation results will be stored.

=cut

sub run_with_state($self, $device, $device_report_id, $data) {
    Mojo::Exception->throw("Device must be defined") unless $device;
    Mojo::Exception->throw("Device Report ID must be defined") unless $device_report_id;
    Mojo::Exception->throw("Validation data must be a hashref")
        unless ref($data) eq 'HASH';

	my $new_results = $self->run_validations( $device, $data );

	my $state = Conch::Model::ValidationState->create(
		$device->id,
		$device_report_id,
		$self->id
	);

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
