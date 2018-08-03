=pod

=head1 NAME

Conch::Validation - base class for writing Conch Validations

=head1 SYNOPSIS

	package Conch::Validation::DeviceValidation;
	use Mojo::Base 'Conch::Validation';

	has name        => 'device_validation';
	has version     => 1;
	has category    => 'CPU';
	has description => q/Description of the validation/;

	# Optional schema to validate $input_data before `validate` is run.
	# Specified in simplified JSON-schema format.
	has schema => sub {
		{
			hello => {
				world => { type => 'string' },
				required => ['world']
			}
		}
	};

	sub validate {
		my ($self, $input_data) = @_;

		my $device           = $self->device;
		my $device_settings  = $self->device_settings;
		my $device_location  = $self->device_location;
		my $hardware_vendor  = $self->hardware_product_vendor;
		my $hardware_name    = $self->hardware_product_name;
		my $hardware_profile = $self->hardware_product_profile;

		$self->register_result( expected => 'hello', got => $input_data->{hello} );
	}


=head1 DESCRIPTION

C<Conch::Validation> provides the base class to define and execute Conch
Validations. Validations extend this class by implementing a C<validate>
method.  This method receives the input data (a C<HASHREF>) to be validatated.
This input data hash may be validated by setting the C<schema> attribute with a
schema definition in the L<JSON-schema|http://json-schema.org> format.

_Note_: A root-level C<'object'> type is assumed in the schema. Only top-level
properties need to be defined. All top-level properties are assumed to be
required by default, but you may define the exact set of required properties by
specifying a `required` attribute on the top-level with a list of required
properties names

The validation logic in the C<validate> method will evaluate the input data and
register one or more validation results with the
L<register_result|"register_result"> method. The logic may use device, device
settings, hardware product name, hardware product vendor, and hardware product
profile details to dispatch conditions and evaluation.

Conch Validations should also define values for the C<name>, C<version>,
C<category>, and C<description> attributes. These attributes are used in the
identification of the validation and validation result storage in the
Validation System infrastructure.

Testing Conch Validations should be done with
C<Test::Conch::Validation::test_validation> with TAP-based tests. This
functions tests that Validations define the required attributes and methods,
and allow you to test the validation logic by running test cases against
expected results.

=head1 METHODS

=cut

package Conch::Validation;

use Mojo::Base -base, -signatures;
use Mojo::Exception;
use JSON::Validator;
use Try::Tiny;

use Conch::ValidationError;

has 'name';
has 'version';
has 'description';
has 'schema';
has 'category';

=head2 validation_results

Get the list of all validation results.

=cut

has 'validation_results';

use constant {
	STATUS_ERROR => 'error',
	STATUS_FAIL  => 'fail',
	STATUS_PASS  => 'pass'
};

=head2 new

Construct a Validation object.

All attributes are optional, but executing validation with L<run> will create
an error validation result if . For example, if L<hardware_product_profile> is
used in the definition of L<validate> but the C<hardware_product> attribute is
unspecified during construction with L<new>, the validation will halt and an
error validation result will be created.

=over

=item C<device>

L<Conch::Model::Device> object under validation.

=item C<device_location>

L<Conch::Class::DeviceLocation> object for the device being validated.

=item C<hardware_product>

The expected L<Conch::Class::HardwareProduct> object for the device being validated.

=item C<device_settings>

A key-value C<HASHREF> of device settings stored for the device being
validated. Empty C<HAHSREF> if unspecified.

=item C<result_builder>

An optional C<CODEREF> to construct validation results. If unspecified,
validation results are built as C<HASHREF>s. The C<CODEREF> will be passed a
list of attributes and values (Attributes are 'message', 'name', 'category',
'status', and 'hint') whenever a validation result is created.

=back

=cut

sub new ( $class, %attrs ) {

	bless {
		_device                    => $attrs{device},
		_device_location           => $attrs{device_location},
		_hardware_product          => $attrs{hardware_product},
		_device_settings           => $attrs{device_settings} || {},
		_validation_result_builder => $attrs{result_builder} || sub { return {@_} },
		validation_results         => []
	}, $class;

}

=head2 run

Run the Validation with the specified input data.

	$validation->run($validation_data);

=cut

sub run ( $self, $data ) {

	try { $self->run_unsafe($data) }
	catch {
		my $validation_error = $self->{_validation_result_builder}->(
			message  => $_->message,
			name     => $self->name,
			status   => STATUS_ERROR,
			hint     => $_->hint || $_->error_loc,
			category => $self->category,
		);
		push $self->validation_results->@*, $validation_error;
	};
	return $self;
}

=head2 run_unsafe

Run the Validation with the specified input data. Re-throws any exception raised
during execution as L<Mojo::Exception>

	eval {
		$validation->run_unsafe($validation_data)
	};
	say $@->frames if $@;

=cut

sub run_unsafe ( $self, $data ) {
	local $SIG{__DIE__} = sub {
		my $err = shift;
		if ( $err->isa('Conch::ValidationError') ) {
			return $err;
		}
		else {
			# remove the 'at $filename line $line_number' from the exception
			# message. We might not want to reveal Conch's path
			$err =~ s/ at .+$//;
			$self->die( $err, level => 2 );
		}
	};

	$self->check_against_schema($data);
	$self->validate($data);
}

=head2 check_against_schema

Check the Validation input data against JSON schema, if specified.


=cut

sub check_against_schema ( $self, $data ) {
	return unless $self->schema;
	my $schema_validator = JSON::Validator->new;

	# Try to coerce the values to the schema types, eg. "1" matches 'number'.
	$schema_validator->coerce(1);

	# Shallow copy the schema and pull out the 'required' list
	my $schema   = { $self->schema->%* };
	my $required = delete $schema->{required} || [ keys %{ $schema } ];
	my $full_schema =
		{ type => 'object', properties => $schema, required => $required };

	$schema_validator->schema($full_schema);
	my @errors = $schema_validator->validate($data);
	if (@errors) {
		my $pretty_schema = substr( Data::Printer::np($full_schema), 2 );
		$self->die(
			"Schema errors: @errors",
			hint  => "Input data does not satisfy schema:\n$pretty_schema",
			level => 2
		);
	}
}

=head2 validate

Contains the validation logic for validations.

This method must be re-defined in sub-classes of C<Conch::Validation> or it will
raise an exception.

	package MyValidation;
	use Mojo::Base 'Conch::Validation';

	sub validate {
		my ($self, $data) = @_;
		$self->register_result({ expected => 1, got => $data->{pass} });
	}

=cut

sub validate ( $self, $data ) {
	$self->die( 'Validations must implement the `validate` method in subclass!',
		level => 2 );
}

=head2 device

Get the C<Conch::Model::Device> object under Validation. Use in validation
logic to dispatch on Device attributes.

	my $device = $self->device;
	if ($device->trition_setup) {...}

=cut

sub device ($self) {
	$self->die( "No Device specified for validation", level => 2 )
		unless $self->{_device};
	return $self->{_device};
}

=head2 device_settings

Get device settings assidned to the device under validation. Device settings
are an unblessed hashref. You can use device setting values to provide
conditional evaluation in the validation logic.


	my $threshold = $self->device_settings->{some_threshold};
	return if $self->device_settings->{skip_this_validation};

=cut

sub device_settings ($self) {
	return $self->{_device_settings};
}

=head2 has_device_location

Return a boolean whether the device under validation has been assigned a
location.

=cut

sub has_device_location ($self) {
	return defined( $self->{_device_location} );
}

=head2 device_location

Get the C<Conch::Class::DeviceLocation> object for the device under validation.
This is useful in writing validation logic that may depend on the rack or
location in the rack a device occupies. Throws an error if the device hasn't
been assigned a location.

	my $datacenter_name = $self->device_location->datacenter->name;
	my $rack_unit = $self->device_location->rack->unit;
	my $rack_slots = $self->device_location->rack->slots;

=cut

sub device_location ($self) {
	$self->die(
		"Device must be assigned a location.",
		hint  => "Assign this device to a rack slot before running this validation",
		level => 2
	) unless $self->{_device_location};
	return $self->{_device_location};
}

=head2 hardware_product_name

Get the expected hardware product name for the device under validation.

	if ($self->hardware_product_name eq 'Joyent-123') {...}

=cut

sub hardware_product_name ($self) {
	$self->die( "Validation must have an expected hardware product", level => 2 )
		unless $self->{_hardware_product};
	return $self->{_hardware_product}->name;
}

=head2 hardware_legacy_product_name

Get the expected hardware legacy product name for the device under validation.

	if ($self->hardware_legacy_product_name eq 'Joyent-123') {...}

=cut

sub hardware_legacy_product_name ($self) {
	$self->die( "Validation must have an expected hardware product", level => 2 )
		unless $self->{_hardware_product};
	return $self->{_hardware_product}->legacy_product_name;
}


=head2 hardware_product_generation

Get the expected hardware product generation for the device under validation.

	if ($self->hardware_product_generation eq 'Joyent-123') {...}

=cut
sub hardware_product_generation ($self) {
	$self->die( "Validation must have an expected hardware product", level => 2 )
		unless $self->{_hardware_product};
	return $self->{_hardware_product}->generation_name;
}

=head2 hardware_product_sku

Get the expected hardware product SKU for the device under validation.

	if ($self->hardware_product_sku eq 'Joyent-123') {...}

=cut

sub hardware_product_sku ($self) {
	$self->die( "Validation must have an expected hardware product", level => 2 )
		unless $self->{_hardware_product};
	return $self->{_hardware_product}->sku;
}

=head2 hardware_product_specification
Get the expected hardware product specification for the device under
validation. Returns a JSON object.
=cut

sub hardware_product_specification ($self) {
	$self->die( "Validation must have an expected hardware product", level => 2 )
		unless $self->{_hardware_product};
	return $self->{_hardware_product}->specification;
}

=head2 hardware_product_vendor

Get the expected hardware product vendor name for the device under validation.

	if ($self->hardware_product_vendor eq 'Dell') {...}

=cut

sub hardware_product_vendor ($self) {
	$self->die( "Validation must have an expected hardware product", level => 2 )
		unless $self->{_hardware_product};
	return $self->{_hardware_product}->vendor;
}

=head2 hardware_product_profile

Get the expected hardware product profile for the device under validation. In
production, the product profile is a C<Conch::Class:HardareProductProfile> object.

	my $expected_ram = self->hardware_product_profile->ram_total;
	my $expected_ssd = self->hardware_product_profile->ssd_num;
	my $expected_firmware = self->hardware_product_profile->bios_firmware;

=cut

sub hardware_product_profile ($self) {
	$self->die( "Validation must have an expected hardware product", level => 2 )
		unless $self->{_hardware_product};
	return $self->{_hardware_product}->profile;
}

=head2 register_result

Register a Validation Result in the validation logic. C<register_result> may be
called as many times as desired in a C<validate> method.

Instead of calculating whether a result should pass or fail in the validation
logic, provide an 'expected' value, the 'got' value, and a comparison operator.
This declarative syntax allows for result de-duplication and consistent messages.


	# direct comparison
	$self->register_result( expected => 'hello', got => 'hello' );
	$self->register_result( expected => 42, got => 42 );

	# specified comparison operator
	$self->register_result( expected => 1, got => 2, cmp => '>=' );
	$self->register_result( expected => 'second', got => 'first', cmp => 'lt' );

	# using 'like' to match with a regex
	$self->register_result( expected => qr/.+bar.+/, got => 'foobarbaz', cmpself => 'like' );

	# using 'oneOf' to select one of multiple values
	$self->register_result( expected => ['a', 'b', 'c' ], got => 'b', cmp => 'oneOf' );

The default operator is 'eq'. The available comparison operators are:

	'==', '!=', '>', '>=', '<', '<=', '<=',
	'eq', 'ne', 'lt', 'le', 'gt', 'ge',
	'like' (regex comparison), 'oneOf' (list membership comparison)

You may also provide the following attributes to override validation results

=over

=item C<name>

By default, the validation result stores the C<name> attribute of the
Validation class. You may override the validation result name with this
attribute.

	$self->register_result(
		expected => 'hello',
		got      => 'hello',
		name     => 'hello_validation'
	);

=item C<message>

The default message stored in the validation result has the form, "Expected
$operator '$expected_value'. Got '$got_value'.". You may override this message
by specifying the C<message> attribute.

	$self->register_result(
		expected => 'hello',
		got      => 'hello',
		message  => 'Hello world!'
	);

=item C<category>

By default, the validation result stores the C<category> attribute of the
Validation class. You may override the validation result category with this
attribute.

	$self->register_result(
		expected => 'hello',
		got      => 'hello',
		category => 'BIOS'
	);

=item C<component_id>

You may specify the optional string attribute C<component_id> to set an
identifier to help identify a specific component under test.

	$self->register_result(
		expected     => 'OK',
		got          => $disk->{health},
		component_id => $disk->{serial_number}
	);

=item C<hint>

You may specify the optional string attribute C<hint> to be stored B<if>
the validation fails. This string should help identify to a user how to fix the
validation failure. If the validation succeeds, the hint string is not stored
in the validation result.

	$self->register_result(
		expected  => 'hello',
		got       => 'bye',
		hint      => "Try saying 'hello' instead"
	);

=back

=cut

sub register_result ( $self, %attrs ) {
	my $expected = $attrs{expected};
	my $got      = $attrs{got};
	my $cmp_op   = $attrs{cmp} || 'eq';

	$self->die( "'expected' value must be defined", level => 2 )
		unless defined($expected);

	return $self->fail("'got' value is undefined") unless defined($got);

	$self->die( "'got' value must be a scalar", level => 2 ) if ref($got);

	if ( $cmp_op eq 'oneOf' ) {
		$self->die( "'expected' value must be an array when comparing with 'oneOf'",
			level => 2 )
			unless ref($expected) eq 'ARRAY';
	}
	elsif ( $cmp_op eq 'like' ) {
		$self->die(
			"'expected' value must be a scalar or Regexp when comparing with 'like'",
			level => 2
		) unless ref($expected) eq 'Regexp' || ref($expected) eq '';
	}
	else {
		$self->die(
			"'expected' value must be a scalar when comparing with '$cmp_op'",
			level => 2 )
			if ref($expected);
	}

	my $cmp_dispatch = {
		'=='  => sub { $_[0] == $_[1] },
		'!='  => sub { $_[0] != $_[1] },
		'>'   => sub { $_[0] > $_[1] },
		'>='  => sub { $_[0] >= $_[1] },
		'<'   => sub { $_[0] < $_[1] },
		'<='  => sub { $_[0] <= $_[1] },
		'<='  => sub { $_[0] <= $_[1] },
		eq    => sub { $_[0] eq $_[1] },
		ne    => sub { $_[0] ne $_[1] },
		lt    => sub { $_[0] lt $_[1] },
		le    => sub { $_[0] le $_[1] },
		gt    => sub { $_[0] gt $_[1] },
		ge    => sub { $_[0] ge $_[1] },
		like  => sub { $_[0] =~ /$_[1]/ },
		oneOf => sub {
			scalar( grep { $_[0] eq $_ } $_[1]->@* );
		}
	};

	my $success = $cmp_dispatch->{$cmp_op}->( $got, $expected );
	my $message;
	if ( $cmp_op eq 'oneOf' ) {
		$message =
			  'Expected one of: '
			. join( ', ', map { "'$_'" } $expected->@* )
			. ". Got '$got'.";
	}

	# For relational operators, we want to produce messages that do not change
	# between validation executions as long as the relation is constant.
	elsif ( grep /$cmp_op/, ( '>', '>=', '<', '<=', 'lt', 'le', 'gt', 'ge' ) ) {
		$message = "Expected a value $cmp_op '$expected'.";
		$message .= $success ? ' Passed.' : ' Failed.';
	}
	else {
		$message = "Expected $cmp_op '$expected'. Got '$got'.";
	}

	my $validation_result = $self->{_validation_result_builder}->(
		message  => $attrs{message}  || $message,
		name     => $attrs{name}     || $self->name,
		category => $attrs{category} || $self->category,
		component_id => $attrs{component_id},
		status       => $success ? STATUS_PASS : STATUS_FAIL,
		hint         => $success ? $attrs{hint} : undef
	);

	push $self->validation_results->@*, $validation_result;
	return $self;

}

=head2 die

Stop execution of the Validation immediately and record an error. The
attributes 'level' and 'hint' may be specified.

	$self->die('This validation cannot continue!') if $bad_condition;
	$self->die('This validation cannot continue!', hint => 'Here's how to fix it' );
	$self->die('This exception happend 3 frames up', level => 3 );

=cut

sub die ( $self, $message, %args ) {

	die Conch::ValidationError->new($message)->hint( $args{hint} )
		->trace( $args{level} || 1 );
}

=head2 fail

Record a failing validation result with a message and continues execution. This
may be useful if you cannot validate some part of the input data but want to
continue validating other parts of the data.


	$self->fail('This validation fails but validation evaluation will continue')
		unless defined( $data->{required_value} );

The attributes C<name>, C<category>, C<component_id>, and C<hint> may be
specified like with C<register_result>.

	$self->fail('I fail!',
		name => 'some_component_validation',
		hint => 'How to fix this failure...'
	);

=cut

sub fail ( $self, $message, %attrs ) {
	my $validation_result = $self->{_validation_result_builder}->(
		message      => $message,
		name         => $attrs{name} || $self->name,
		category     => $attrs{category} || $self->category,
		component_id => $attrs{component_id},
		status       => STATUS_FAIL,
		hint         => $attrs{hint}
	);
	push $self->validation_results->@*, $validation_result;
	return $self;
}

=head2 failures

Get the list of validation results that were failures

=cut

sub failures ( $self ) {
	[ grep { $_->{status} eq STATUS_FAIL } $self->validation_results->@* ];
}

=head2 successes

Get the list of validation results that were successful

=cut

sub successes ( $self ) {
	[ grep { $_->{status} eq STATUS_PASS } $self->validation_results->@* ];
}

=head2 error

Get the list of validation results that have error status (halted execution).

I<NOTE:> Unless C<run> is called multiple times on the same validation object
without calling C<clear_results> between, there should be at most 1 error
validation because execution is halted.

=cut

sub error ( $self ) {
	[ grep { $_->{status} eq STATUS_ERROR } $self->validation_results->@* ];
}

=head2 clear_results

Clear the stored validation results.

=cut

sub clear_results ( $self ) {
	$self->validation_results( [] );
	return $self;
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
