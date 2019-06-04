# NAME

Conch::Validation - base class for writing Conch Validations

# SYNOPSIS

```perl
package Conch::Validation::DeviceValidation;
# either:
    use Mojo::Base 'Conch::Validation';
# or, if you want to use Moo features:
    use Moo;
    use strictures 2;
    extends 'Conch::Validation';

use constant name        => 'device_validation';
use constant version     => 1;
use constant category    => 'CPU';
use constant description => q/Description of the validation/;

sub validate {
    my ($self, $input_data) = @_;

    my $device           = $self->device;
    my $device_settings  = $self->device_settings;
    my $device_location  = $self->device_location;
    my $hardware_vendor  = $self->hardware_product_vendor;
    my $hardware_name    = $self->hardware_product_name;
    my $hardware_profile = $self->hardware_product_profile;

    $self->register_result(expected => 'hello', got => $input_data->{hello});
}
```

# DESCRIPTION

[Conch::Validation](../modules/Conch::Validation) provides the base class to define and execute Conch
Validations. Validations extend this class by implementing a ["validate"](#validate)
method.  This method receives the input data (a `HASHREF`) to be validated.

The validation logic in the ["validate"](#validate) method will evaluate the input data and
register one or more validation results with the
["register\_result"](#register_result) method. The logic may use device, device
settings, hardware product name, hardware product vendor, and hardware product
profile details to dispatch conditions and evaluation.

Conch Validations should also define values for the `name`, `version`,
`category`, and `description` attributes. These attributes are used in the
identification of the validation and validation result storage in the
Validation System infrastructure.

Testing Conch Validations should be done with
["test\_validation" in Test::Conch::Validation](../modules/Test::Conch::Validation#test_validation) with TAP-based tests. This
functions tests that Validations define the required attributes and methods,
and allow you to test the validation logic by running test cases against
expected results.

# CONSTANTS

## name

The validator name, provided by the validator module.

## version

The validator version, provided by the validator module.

## description

The validator description, provided by the validator module.

## category

The validator category, provided by the validator module.

# METHODS

## log

A logging object.

## device

[Conch::DB::Result::Device](../modules/Conch::DB::Result::Device) object under validation.  Use in validation
logic to dispatch on Device attributes.

```perl
my $device = $self->device;
if ($device->asset_tag eq '...') {...}
```

Any additional data related to devices may be read as normal using [DBIx::Class](https://metacpan.org/pod/DBIx::Class) interfaces.
The result object is built using a read-only database handle, so attempts to alter the data
will \*not\* be permitted.

## device\_location

[Conch::DB::Result::DeviceLocation](../modules/Conch::DB::Result::DeviceLocation) object for the device being validated.

This is useful in writing validation logic that may depend on the rack or
location in the rack a device occupies.

```perl
my $datacenter_name = $self->device_location->rack->datacenter->name;
my $rack_unit_start = $self->device_location->rack_unit_start;
```

## has\_device\_location

Returns a boolean whether the device under validation has been assigned a
location.

## hardware\_product

The expected [Conch::DB::Result::HardwareProduct](../modules/Conch::DB::Result::HardwareProduct) object for the device being validated.
Note that this is **either** the hardware\_product associated with the rack and slot the device
is located in, **or** the hardware\_product associated with the device itself (when the device is
not located in a rack yet). When this distinction is important, check ["has\_device\_location"](#has_device_location).

Any additional data related to hardware\_products may be read as normal using [DBIx::Class](https://metacpan.org/pod/DBIx::Class)
interfaces.  The result object is built using a read-only database handle, so attempts to alter
the data will \*not\* be permitted.

## hardware\_product\_name

Get the expected hardware product name for the device under validation.

```perl
if ($self->hardware_product_name eq 'Joyent-123') {...}
```

## hardware\_legacy\_product\_name

Get the expected hardware legacy product name for the device under validation.

```perl
if ($self->hardware_legacy_product_name eq 'Joyent-123') {...}
```

## hardware\_product\_generation

Get the expected hardware product generation for the device under validation.

```perl
if ($self->hardware_product_generation eq 'Joyent-123') {...}
```

## hardware\_product\_sku

Get the expected hardware product SKU for the device under validation.

```perl
if ($self->hardware_product_sku eq 'Joyent-123') {...}
```

## hardware\_product\_specification

Get the expected hardware product specification for the device under
validation. Returns a JSON string (for now).

## hardware\_product\_vendor

Get the expected hardware product vendor name for the device under validation.

```perl
if ($self->hardware_product_vendor eq 'Dell') {...}
```

## hardware\_product\_profile

Get the expected hardware product profile for the device under validation.
It is a [Conch::DB::Result::HardwareProductProfile](../modules/Conch::DB::Result::HardwareProductProfile) object.

```perl
my $expected_ram = self->hardware_product_profile->ram_total;
my $expected_ssd = self->hardware_product_profile->ssd_num;
my $expected_firmware = self->hardware_product_profile->bios_firmware;
```

## device\_settings

A key-value unblessed hashref of device settings stored for the device being validated.

## validation\_results

Get the list of all validation results.

## validation\_result

Get a validation result by (0-based) index.

## failures

Get the list of validation results that were failures

## successes

Get the list of validation results that were successful

## error

Get the list of validation results that have error status (halted execution).

_NOTE:_ Unless ["run"](#run) is called multiple times on the same validation object
without calling ["clear\_results"](#clear_results) between, there should be at most 1 error
validation because execution is halted.

## clear\_results

Clear the stored validation results.

## run

Run the Validation with the specified input data.

```
$validation->run($validation_data);
```

## validate

Contains the validation logic for validations.

This method must be re-defined in sub-classes of [Conch::Validation](../modules/Conch::Validation) or it will
raise an exception.

```perl
package MyValidation;
use Mojo::Base 'Conch::Validation';

sub validate {
    my ($self, $data) = @_;
    $self->register_result({ expected => 1, got => $data->{pass} });
}
```

## register\_result

Register a Validation Result in the validation logic. ["register\_result"](#register_result) may be
called as many times as desired in a ["validate"](#validate) method.

Instead of calculating whether a result should pass or fail in the validation
logic, provide an 'expected' value, the 'got' value, and a comparison operator.
This declarative syntax allows for result deduplication and consistent messages.

```perl
# direct comparison
$self->register_result(expected => 'hello', got => 'hello');
$self->register_result(expected => 42, got => 42);

# specified comparison operator
$self->register_result(expected => 1, got => 2, cmp => '>=');
$self->register_result(expected => 'second', got => 'first', cmp => 'lt');

# using 'like' to match with a regex
$self->register_result(expected => qr/.+bar.+/, got => 'foobarbaz', cmpself => 'like');

# using 'oneOf' to select one of multiple values
$self->register_result(expected => ['a', 'b', 'c' ], got => 'b', cmp => 'oneOf');
```

The default operator is 'eq'. The available comparison operators are:

```
'==', '!=', '>', '>=', '<', '<=', '<=',
'eq', 'ne', 'lt', 'le', 'gt', 'ge',
'like' (regex comparison), 'oneOf' (list membership comparison)
```

You may also provide the following attributes to override validation results

- `name`

    By default, the validation result logs the `name` attribute of the
    Validation class. You may override the validation result name with this
    attribute.

    This value is not stored in the database. To disambiguate multiple results in the database, use
    `component`.

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

- `category`

    By default, the validation result stores the `category` attribute of the
    Validation class. You may override the validation result category with this
    attribute.

    ```perl
    $self->register_result(
        expected => 'hello',
        got      => 'hello',
        category => 'BIOS'
    );
    ```

- `component`

    You may specify the optional string attribute `component` to set an
    identifier to help identify a specific component under test.

    ```perl
    $self->register_result(
        expected     => 'OK',
        got          => $disk->{health},
        component    => $disk->{serial_number}
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

## register\_result\_cmp\_details

EXPERIMENTAL. A new way of registering validation results. Pass arguments as you would to
["cmp\_deeply" in Test::Deep](https://metacpan.org/pod/Test::Deep#cmp_deeply), and a validation result is registered with the result and diagnostics
as appropriate.

## die

Stop execution of the Validation immediately and record an error. The
attributes 'level' and 'hint' may be specified.

```perl
$self->die('This validation cannot continue!') if $bad_condition;
$self->die('This validation cannot continue!', hint => 'Here's how to fix it');
$self->die('This exception happend 3 frames up', level => 3);
```

## fail

Record a failing validation result with a message and continues execution. This
may be useful if you cannot validate some part of the input data but want to
continue validating other parts of the data.

```perl
$self->fail('This validation fails but validation evaluation will continue')
    unless defined($data->{required_value});
```

The attributes `name`, `category`, `component`, and `hint` may be
specified like with ["register\_result"](#register_result).

```perl
$self->fail('I fail!',
    name => 'some_component_validation',
    hint => 'How to fix this failure...'
);
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
