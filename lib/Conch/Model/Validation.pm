=pod

=head1 NAME

Conch::Model::Validation

=head1 METHODS

=cut

package Conch::Model::Validation;
use Mojo::Base -base, -signatures;

use Conch::Pg;
use Conch::Model::DeviceSettings;
use Conch::Model::DeviceLocation;
use Conch::Model::HardwareProduct;
use Conch::Model::ValidationResult;

my $attrs = [qw( id name version description module created updated)];
has $attrs;

use Conch::Log;
has 'log' => sub { return Conch::Log->new };

=head2 new

Create a new Validation.
	
	Conch::Model::Validation->new (
		name        => 'example_validation',
		version     => 1,
		description => 'Example Validation',
		module      => 'Conch::Validation::ExampleValidation',
	);

All unspecified fields will be 'undef'.

=cut

sub new ( $class, %args ) {
	$class->SUPER::new( %args{@$attrs} );
}

=head2 TO_JSON

Render as a hashref for output

=cut

sub TO_JSON ($self) {
	{
		id          => $self->id,
		name        => $self->name,
		version     => $self->version,
		description => $self->description,
		created     => Conch::Time->new( $self->created ),
		updated     => Conch::Time->new( $self->updated )
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
		Conch::Pg->new->db->select( 'validation', $attrs,
		{ id => $id, deactivated => undef } )->hash;
	return $class->new( $ret->%* ) if $ret;
}

=head2 lookup_by_name_and_version

Lookup a validation by name and version

=cut

sub lookup_by_name_and_version ( $class, $name, $version ) {
	my $ret =
		Conch::Pg->new->db->select( 'validation', $attrs,
		{ name => $name, version => $version, deactivated => undef } )->hash;
	return $class->new( $ret->%* ) if $ret;
}

=head2 list

List all active Validations

=cut

sub list ( $class ) {
	Conch::Pg->new->db->select( 'validation', $attrs, { deactivated => undef } )
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

sub build_device_validation ( $self, $device, $hardware_product,
	$device_location, $device_settings )
{

	# Device and hardware product are required for storing validation results
	Mojo::Exception->throw("Device must be defined") unless $device;
	Mojo::Exception->throw("Hardware product must be defined")
		unless $hardware_product;

	my $module = $self->module;

	my $order          = 0;
	my $result_builder = sub {
		return Conch::Model::ValidationResult->new(
			@_,

			# each time a ValidationResult is created, increment order value
			# post-assignment. This allows us to distinguish between multiples
			# of similar results
			result_order        => $order++,
			validation_id       => $self->id,
			validation_id       => $self->id,
			device_id           => $device->id,
			hardware_product_id => $hardware_product->id
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

=head2 run_validation_for_device

Run the L<Conch::Validation> sub-class with the given device
(L<Conch::Model::Device>). Finds the location, settings, and expected hardware
product for the Device. Returns the validation results.

=cut

sub run_validation_for_device ( $self, $device, $data ) {
	my $location = Conch::Model::DeviceLocation->lookup( $device->id );
	my $settings = Conch::Model::DeviceSettings->get_settings( $device->id );

	my $hw_product_id =
		  $location
		? $location->target_hardware_product->id
		: $device->hardware_product;
	my $hw_product = Conch::Model::HardwareProduct->lookup($hw_product_id);

	my $validation =
		$self->build_device_validation( $device, $hw_product, $location,
		$settings );

	$validation->log($self->log);
	$validation->run($data);
	return $validation->validation_results;
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
