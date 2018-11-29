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

my $attrs = [qw( id name version description module created updated)];
has $attrs;

has 'log' => sub { Carp::croak('missing logger') };

=head2 new

Create a new Validation.
	
	Conch::Model::Validation->new (
		log         => $logger,      # main logger object from mojo app or controller
		name        => 'example_validation',
		version     => 1,
		description => 'Example Validation',
		module      => 'Conch::Validation::ExampleValidation',
	);

All unspecified fields will be 'undef'.

=cut

sub new ( $class, %args ) {
	$class->SUPER::new( %args{@$attrs, 'log'} );
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
		log              => $self->log,
		device           => $device,
		device_location  => $device_location,
		device_settings  => $device_settings,
		hardware_product => $hardware_product,
		result_builder   => $result_builder
	);
	return $validation;
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
