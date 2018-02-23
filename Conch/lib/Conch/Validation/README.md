<!-- generated with `pod2github lib/Conch/Validation.pm > lib/Conch/Validation/README.md` -->
## Name

Conch::Validation - base class for writing Conch Validations

## Synopsis

```perl
    package Conch::Validation::DeviceValidation;
    use Mojo::Base 'Conch::Validation';

    has name => 'device_validation';
    has version => 1;
    has description => q/Description of the validation/;

    # Optional schema to validate $input_data before `validate` is run.
    # Specified in the JSON-schema format.
    has schema => sub {
            {
                    required => [ 'hello' ],
                    properties => {
                            hello => { type => 'string' }
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
```

## Methods

### Validation\_Results

Get the list of all validation results.

### New

Construct a Validation object.

All attributes are optional, but executing validation with [run](https://metacpan.org/pod/run) will create
an error validation result if . For example, if [hardware\_product\_profile](https://metacpan.org/pod/hardware_product_profile) is
used in the definition of [validate](https://metacpan.org/pod/validate) but the `hardware_product` attribute is
unspecified during construction with [new](https://metacpan.org/pod/new), the validation will halt and an
error validation result will be created.

- `device`

    [Conch::Model::Device](https://metacpan.org/pod/Conch::Model::Device) object under validation.

- `device_location`

    [Conch::Class::DeviceLocation](https://metacpan.org/pod/Conch::Class::DeviceLocation) object for the device being validated.

- `hardware_product`

    The expected [Conch::Class::HardwareProduct](https://metacpan.org/pod/Conch::Class::HardwareProduct) object for the device being validated.

- `device_settings`

    A key-value `HASHREF` of device settings stored for the device being
    validated. Empty `HAHSREF` if unspecified.

- `result_builder`

    An optional `CODEREF` to construct validation results. If unspecified,
    validation results are built as `HASHREF`s. The `CODEREF` will be passed a
    list of attributes and values (Attributes are 'message', 'name', 'status',
    'hint') whenever a validation result is registered.

### Run

Run the Validation with the specified input data.

```
    $validation->run($validation_data);
```

### Run\_Unsafe

Run the Validation with the specified input data. Re-throws any exception raised
during execution as [Mojo::Exception](https://metacpan.org/pod/Mojo::Exception)

```
    eval {
            $validation->run_unsafe($validation_data)
    };
    say $@->frames if $@;
```

### Check\_Against\_Schema

Check the Validation input data against the JSON schema, if specified.

### Validate

Contains the validation logic for validations.

This method must be re-defined in sub-classes of `Conch::Validation` or it will
raise an exception.

```perl
    package MyValidation;
    use Mojo::Base 'Conch::Validation';

    sub validate {
            my ($self, $data) = @_;
            $self->register_result({ expected => 1, got => $data->{pass} });
    }
```

### Device

Get the `Conch::Model::Device` object under Validation. Use in validation
logic to dispatch on Device attributes.

```perl
    my $device = $self->device;
    if ($device->trition_setup) {...}
```

### Device\_Settings

Get device settings assidned to the device under validation. Device settings
are an unblessed hashref. You can use device setting values to provide
conditional evaluation in the validation logic.

```perl
    my $threshold = $self->device_settings->{some_threshold};
    return if $self->device_settings->{skip_this_validation};
```

### Device\_Location

Get the `Conch::Class::DeviceLocation` object for the device under validation.
This is useful in writing validation logic that may depend on the rack or
location in the rack a device occupies. Throws an error if the device hasn't
been assigned a location.

```perl
    my $datacenter_name = $self->device_location->datacenter->name;
    my $rack_unit = $self->device_location->rack->unit;
    my $rack_slots = $self->device_location->rack->slots;
```

### Hardware\_Product\_Name

Get the expected hardware product name for the device under validation.

```perl
    if ($self->hardware_product_name eq 'Joyent-123') {...}
```

### Hardware\_Product\_Vendor

Get the expected hardware product vendor name for the device under validation.

```perl
    if ($self->hardware_product_vendor eq 'Dell') {...}
```

### Hardware\_Product\_Profile

Get the expected hardware product profile for the device under validation. In
production, the product profile is a `Conch::Class:HardareProductProfile` object.

```perl
    my $expected_ram = self->hardware_product_profile->ram_total;
    my $expected_ssd = self->hardware_product_profile->ssd_num;
    my $expected_firmware = self->hardware_product_profile->bios_firmware;
```

### Register\_Result

Register a Validation Result in the validaiton logic. `register_result` may be
called as many times as desired in a `validate` method.

Instead of calculating whether a result should pass or fail in the validaiton
logic, provide an 'expected' value, the 'got' value, and a comparison operator.
This declarative syntax allows for result de-duplication and consistent messages.

```perl
    # direct comparison
    $self->register_result( expected => 'hello', got => 'hello' );
    $self->register_result( expected => 42, got => 42 );

    # specified comparison operator
    $self->register_result( expected => 1, got => 2, cmp => '>=' );
    $self->register_result( expected => 'second', got => 'first', cmp => 'lt' );

    # using 'like' to match with a regex
    $self->register_result( expected => qr/.+bar.+/, got => 'foobarbaz', cmp => 'like' );

    # using 'oneOf' to select one of multiple values
    $self->register_result( expected => ['a', 'b', 'c' ], got => 'b', cmp => 'oneOf' );
```

The default operator is 'eq'. The available comparison operators are:

```
    '==', '!=', '>', '>=', '<', '<=', '<=',
    'eq', 'ne', 'lt', 'le', 'gt', 'ge',
    'like' (regex comparison), 'oneOf' (list membership comparison)
```

You may also provide the following attributes to override validation results

- `name`

    By default, the validation result stores the `name` attribute of the Validation class. You
    may override the validation result name with this attribute

    ```perl
        $self->register_result(
                expected => 'hello',
                got      => 'hello',
                name     => 'hello_validation'
        );
    ```

- `message`

    The default message stored in the validation result has the form, "Expected
    $operator '$expected\_value'. Got '$got\_value'.". You may override this message
    by specifying the `message` attribute.

    ```perl
        $self->register_result(
                expected => 'hello',
                got      => 'hello',
                message  => 'Hello world!'
        );
    ```

- `hint`

    You may specify the optional string attribute `hint` to be stored **if**
    the validation fails. This string should help identify to a user how to fix the
    validation failure. If the validation succeeds, the hint string is not stored
    in the validation result.

    ```perl
        $self->register_result(
                expected  => 'hello',
                got       => 'bye',
                hint      => "Try saying 'hello' instead"
        );
    ```

### Die

Stop execution of the Validation immediately and record an error.

```perl
    $self->die('This validation cannot continue!') if $bad_condition;
```

### Fail

Record a failing validaiton result with a message and continues execution. This
may be useful if you cannot validate some part of the input data but want to
continue validating other parts of the data.

```perl
    $self->fail('This validation fails but validation evaluation will continue')
            unless defined( $data->{required_value} );
```

The attributes `name` and `hint` may be specified like with `register_result`.

```perl
    $self->fail('I fail!',
            name => 'some_component_validation',
            hint => 'How to fix this failure...'
    );
```

### Failures

Get the list of validation results that were failures

### Successes

Get the list of validation results that were successful

### Error

Get the list of validation results that have error status (halted execution).

_NOTE:_ Unless `run` is called multiple times on the same validation object
without calling `clear_results` between, there should be at most 1 error
validation because execution is halted.

### Clear\_Results

Clear the stored validation results.

## Licensing

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
