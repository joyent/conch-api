=pod

=head1 NAME

Conch::Model::Validation

=head1 METHODS

=cut

package Conch::Model::Validation;
use Mojo::Base -base, -signatures;

use Conch::Pg;
use Conch::Model::DeviceLocation;
use Conch::Model::HardwareProduct;
use Conch::Model::ValidationResult;

my $attrs =
	[qw( id name version description module persistence created updated)];
has $attrs;

=head2 output_hash

Render as a hashref for output

=cut

sub output_hash ($self) {
	{
		id          => $self->id,
		name        => $self->name,
		version     => $self->version,
		description => $self->description,
		created     => Conch::Time->new( $self->created )->rfc3339,
		updated     => Conch::Time->new( $self->updated )->rfc3339
	};
}

=head2 create

Create a new Validation. May throw error if Validation with the same name and version already exist.
Use C<upsert> to avoid this.

=cut

sub create ( $class, $name, $version, $description, $module ) {
	my $ret = Conch::Pg->new->db->insert(
		'validation',
		{
			name        => $name,
			version     => $version,
			description => $description,
			module      => $module
		},
		{ returning => $attrs }
	)->hash;
	return $class->new( $ret->%* );
}

=head2 upsert

Create or update a Validation if it already exists and has changed.

Returns undef if the Validation matches exactly an existing Validation.

=cut

sub upsert ( $class, $name, $version, $description, $module ) {
	my $returning = join ', ', $attrs->@*;
	my $ret = Conch::Pg->new->db->query(
		qq{
			INSERT INTO validation AS v
				(name, version, description, module)
			VALUES (?, ?, ?, ?)
			ON CONFLICT (name, version)
			DO UPDATE SET
				description = EXCLUDED.description,
				module      = EXCLUDED.module,
				updated     = current_timestamp
			WHERE
				v.description != EXCLUDED.description OR
				v.module      != EXCLUDED.module
			RETURNING $returning
		},
		$name, $version, $description, $module
	)->hash;
	return $class->new( $ret->%* ) if $ret;
}

=head2 lookup

Lookup a validation by ID

=cut

sub lookup ( $class, $id ) {
	my $ret =
		Conch::Pg->new->db->select( 'validation', undef,
		{ id => $id, deactivated => undef } )->hash;
	return $class->new( $ret->%* ) if $ret;
}

=head2 list

List all active Validations

=cut

sub list ( $class ) {
	Conch::Pg->new->db->select( 'validation', undef, { deactivated => undef } )
		->hashes->map( sub { $class->new( shift->%* ) } )->to_array;
}

=head2 build_device_validation

Build a L<Conch::Validation> sub-class object with the given device
(L<Conch::Model::Device>, device location (L<Conch::Class::DeviceLocation>),
device settings (hashref), and exepcted hardware product
(L<Conch::Class::HardwareProduct>). Any of these may be 'undef', but the
Validation will create an error Validation Result if these objects are expected
in the validation logic.

Run the returned Validation with `->run($input_data)`.

=cut

sub build_device_validation ( $self, $device, $device_location,
	$device_settings, $hardware_product )
{

	my $module = $self->module;

	my $result_builder = sub {
		return Conch::Model::ValidationResult->new(
			@_,
			validation_id       => $self->id,
			validation_id       => $self->id,
			device_id           => $device && $device->id,
			hardware_product_id => $hardware_product && $hardware_product->id
		);
	};

	my $validation = $module->new(
		device           => $device,
		device_location  => $device_location,
		device_settings  => $device_settings,
		hardware_product => $hardware_product,
		result_builder   => $result_builder
	);
	return $validation;
}

=head2 build_validation_for_device

Build the L<Conch::Validation> sub-class with the given device
(L<Conch::Model::Device>). Finds the location, settings, and expected hardwar
product for the Device.

=cut

sub build_validation_for_device ( $self, $device ) {
	my $location   = Conch::Model::DeviceLocation->lookup( $device->id );
	my $settings   = Conch::Model::DeviceSettings->get_settings( $device->id );
	my $hw_product = Conch::Model::HardwareProduct->lookup(
		$location->target_hardware_product->id )
		if $location;
	return $self->build_device_validation( $device, $location, $settings,
		$hw_product );
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
